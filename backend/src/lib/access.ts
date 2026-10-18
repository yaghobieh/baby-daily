import type { Role } from '@prisma/client';
import { prisma } from '../db.js';
import { forbidden, notFound } from './errors.js';

const RANK: Record<Role, number> = { VIEWER: 1, CAREGIVER: 2, OWNER: 3 };

/**
 * Authorization gate used by EVERY baby-scoped route.
 * Throws 404 if the user is not a member (don't leak existence), 403 if role too low.
 */
export async function requireMember(babyId: string, userId: string, minRole: Role = 'VIEWER') {
  const member = await prisma.babyMember.findUnique({
    where: { babyId_userId: { babyId, userId } },
  });
  if (!member) throw notFound('baby_not_found');
  if (RANK[member.role] < RANK[minRole]) throw forbidden('insufficient_role');
  return member;
}

export function hasRole(role: Role, minRole: Role) {
  return RANK[role] >= RANK[minRole];
}
