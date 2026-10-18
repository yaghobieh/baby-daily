import 'dotenv/config';
import { z } from 'zod';

const EnvSchema = z.object({
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 chars'),
  PORT: z.coerce.number().int().default(5050),
  HOST: z.string().default('0.0.0.0'),
  CORS_ORIGINS: z.string().default('*'),
  FIREBASE_SERVICE_ACCOUNT_BASE64: z.string().optional().default(''),
  NODE_ENV: z.string().default('development'),
  /** Public URL of the web app (used in invitation emails). */
  APP_URL: z.string().default('http://localhost:8080'),
  /** Resend (https://resend.com) API key for transactional email. Without it emails are only logged. */
  RESEND_API_KEY: z.string().optional().default(''),
  EMAIL_FROM: z.string().default('BabyDaily <onboarding@resend.dev>'),
  /** Shared secret for the Vercel cron endpoint. */
  CRON_SECRET: z.string().optional().default(''),
});

const parsed = EnvSchema.safeParse(process.env);
if (!parsed.success) {
  console.error('❌ Invalid environment configuration:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
