// Vercel serverless entry: boots the Fastify app once per instance and forwards requests to it.
import { buildApp } from '../dist/app.js';

let appPromise;

export default async function handler(req, res) {
  appPromise ??= buildApp();
  const app = await appPromise;
  app.server.emit('request', req, res);
}
