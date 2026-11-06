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

  app.get('/privacy', async (req, reply) => {
    reply.type('text/html; charset=utf-8');
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BabyDaily — Privacy Policy</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #2D3748; max-width: 760px; margin: 40px auto; padding: 0 20px; background: #FFF9F7; }
    h1, h2 { color: #E53E3E; }
    .card { background: white; padding: 32px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    footer { margin-top: 32px; font-size: 13px; color: #718096; text-align: center; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Privacy Policy for BabyDaily</h1>
    <p><strong>Last Updated: October 31, 2026</strong></p>
    <p>BabyDaily ("we", "our", or "us") provides a shared baby routine and activity tracker. We respect your privacy and are committed to protecting the personal information you share with us.</p>
    
    <h2>1. Information We Collect</h2>
    <ul>
      <li><strong>Account Details:</strong> Email address, name, and optional phone number when creating an account.</li>
      <li><strong>Baby Routine Data:</strong> Feeding logs, sleep cycles, diaper changes, medications, growth measurements, and photos you choose to log.</li>
      <li><strong>Caregiver Network:</strong> Names and contact information of invited family members or caregivers you authorize to view or edit baby routines.</li>
    </ul>

    <h2>2. How We Use Information</h2>
    <p>We use your data solely to provide, synchronize, and improve BabyDaily services, including real-time family updates, smart routine reminders, and medical export reports.</p>

    <h2>3. Data Sharing & Security</h2>
    <p>We never sell your data or share your personal information with third-party advertising networks. Data is encrypted in transit and securely hosted on trusted cloud infrastructure.</p>

    <h2>4. Account & Data Deletion</h2>
    <p>You can delete your account or any baby profile and related logs directly from the app settings, or by contacting our support team at <strong>privacy@babydaily.app</strong>. All associated data will be permanently removed.</p>

    <h2>5. Contact Us</h2>
    <p>If you have any questions about this Privacy Policy, please contact us at support@babydaily.app.</p>
  </div>
  <footer>&copy; 2026 BabyDaily. All rights reserved.</footer>
</body>
</html>`;
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
