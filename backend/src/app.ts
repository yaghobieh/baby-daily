import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import { env } from './env.js';
import { prisma } from './db.js';
import { HttpError } from './lib/errors.js';
import './lib/http.js';
import authRoutes from './routes/auth.js';
import babyRoutes from './routes/babies.js';
import sharingRoutes from './routes/sharing.js';
import miscRoutes from './routes/misc.js';
import { initPush } from './services/notify.js';
import { tick } from './services/scheduler.js';

/** Builds the Fastify instance (shared by the local server and the Vercel serverless handler). */
export async function buildApp() {
  const app = Fastify({
    logger: { level: env.NODE_ENV === 'production' ? 'info' : 'debug', redact: ['req.headers.authorization'] },
    bodyLimit: 8 * 1024 * 1024, // photos are sent as base64
  });

  await app.register(cors, {
    origin: env.CORS_ORIGINS === '*' ? true : env.CORS_ORIGINS.split(',').map((s) => s.trim()),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  });
  await app.register(jwt, { secret: env.JWT_SECRET });

  app.decorate('authenticate', async (req) => {
    try {
      if (!req.headers.authorization && typeof (req.query as any)?.token === 'string') {
        req.headers.authorization = `Bearer ${(req.query as any).token}`;
      }
      await req.jwtVerify();
    } catch {
      throw new HttpError(401, 'unauthorized');
    }
  });

  // Uniform error shape: { error: <code>, message }
  app.setErrorHandler((err, req, reply) => {
    if (err instanceof ZodError) {
      return reply.code(400).send({ error: 'validation_error', message: err.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ') });
    }
    if (err instanceof HttpError) return reply.code(err.statusCode).send({ error: err.code, message: err.message });
    if (err instanceof Prisma.PrismaClientKnownRequestError) {
      if (err.code === 'P2002') return reply.code(409).send({ error: 'conflict', message: 'Already exists' });
      if (err.code === 'P2025') return reply.code(404).send({ error: 'not_found', message: 'Not found' });
    }
    const status = (err as { statusCode?: number }).statusCode;
    if (status && status < 500) return reply.code(status).send({ error: 'bad_request', message: (err as Error).message });
    req.log.error(err);
    return reply.code(500).send({ error: 'internal_error', message: 'Something went wrong' });
  });

  app.get('/health', async () => {
    await prisma.$queryRaw`SELECT 1`;
    return { ok: true, time: new Date().toISOString() };
  });

  await app.register(authRoutes);
  await app.register(babyRoutes);
  await app.register(sharingRoutes);
  await app.register(miscRoutes);


  // Reminder engine for serverless hosting (Vercel Cron calls this; locally a timer runs instead).
  app.get('/cron/tick', async (req, reply) => {
    if (env.CRON_SECRET && req.headers.authorization !== `Bearer ${env.CRON_SECRET}`) {
      return reply.code(401).send({ error: 'unauthorized', message: 'unauthorized' });
    }
    await tick();
    return { ok: true };
  });

  initPush(app.log);
  await app.ready();
  return app;
}
