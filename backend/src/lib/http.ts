import type { FastifyRequest } from 'fastify';
import type { User } from '@prisma/client';

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: { sub: string };
    user: { sub: string };
  }
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest) => Promise<void>;
  }
}

/** Current authenticated user id (only valid after the `authenticate` hook). */
export const uid = (req: FastifyRequest) => req.user.sub;

export const FREE_DAILY_AI_LIMIT = 3;

/** Public user shape – NEVER return passwordHash. */
export function toUserDto(u: User) {
  const todayUtc = new Date().toISOString().slice(0, 10);
  const queriesUsedToday = u.aiLastQueryDate === todayUtc ? u.aiQueriesToday : 0;
  return {
    id: u.id,
    email: u.email,
    phone: u.phone,
    name: u.name,
    locale: u.locale,
    isPremium: u.isPremium,
    subscriptionPlan: u.subscriptionPlan,
    subscriptionSince: u.subscriptionSince,
    aiQueriesToday: queriesUsedToday,
    aiDailyLimit: u.isPremium ? 9999 : FREE_DAILY_AI_LIMIT,
    dailySummaryEmail: u.dailySummaryEmail,
    createdAt: u.createdAt,
  };
}

export const publicUserSelect = { id: true, name: true, email: true, phone: true } as const;
