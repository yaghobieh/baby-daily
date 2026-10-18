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

/** Public user shape – NEVER return passwordHash. */
export function toUserDto(u: User) {
  return {
    id: u.id,
    email: u.email,
    phone: u.phone,
    name: u.name,
    locale: u.locale,
    createdAt: u.createdAt,
  };
}

export const publicUserSelect = { id: true, name: true, email: true, phone: true } as const;
