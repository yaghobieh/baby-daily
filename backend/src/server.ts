import { env } from './env.js';
import { prisma } from './db.js';
import { buildApp } from './app.js';
import { startScheduler } from './services/scheduler.js';

const app = await buildApp();
startScheduler();

const shutdown = async () => {
  await app.close();
  await prisma.$disconnect();
  process.exit(0);
};
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

await app.listen({ port: env.PORT, host: env.HOST });
