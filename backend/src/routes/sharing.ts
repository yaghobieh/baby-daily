import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import { prisma } from '../db.js';
import { requireMember } from '../lib/access.js';
import { badRequest, conflict, forbidden, notFound } from '../lib/errors.js';
import { normalizeEmail, normalizePhone, phoneKey } from '../lib/contact.js';
import { publicUserSelect, uid } from '../lib/http.js';
import { t } from '../lib/i18n.js';
import { BabyParams, IdParams, InviteBody, MemberParams, MemberPatchBody, SettingsBody } from '../schemas.js';
import { notifyUser } from '../services/notify.js';
import { sendInviteEmail } from '../services/email.js';
import { env } from '../env.js';

/** Sharing: invitations by email/phone, members & roles, per-member notification settings. */
export default async function sharingRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // ---------- Invitations (owner side) ----------
  app.get('/babies/:babyId/invitations', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req), 'OWNER');
    return prisma.invitation.findMany({ where: { babyId, status: 'PENDING' }, orderBy: { createdAt: 'desc' } });
  });

  const inviteHandler = async (req: any, reply: any) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req), 'OWNER');
    const b = InviteBody.parse(req.body);
    const email = normalizeEmail(b.email);
    const phone = normalizePhone(b.phone);
    const pKey = phoneKey(b.phone);
    if (!email && !pKey) throw badRequest('invalid_contact');

    const target = await prisma.user.findFirst({
      where: { OR: [...(email ? [{ email }] : []), ...(pKey ? [{ phoneKey: pKey }] : [])] },
    });
    if (target?.id === uid(req)) throw badRequest('cannot_invite_self');

    const [me, baby] = await Promise.all([
      prisma.user.findUniqueOrThrow({ where: { id: uid(req) }, select: { name: true, locale: true } }),
      prisma.baby.findUniqueOrThrow({ where: { id: babyId }, select: { name: true } }),
    ]);

    let member = null;
    let invitation;
    if (target) {
      // Existing account -> they join right away and get an in-app alert.
      member = await prisma.babyMember.upsert({
        where: { babyId_userId: { babyId, userId: target.id } },
        create: { babyId, userId: target.id, role: b.role, notifyEnabled: true },
        update: { role: b.role, notifyEnabled: true },
      });
      invitation = await prisma.invitation.create({
        data: { babyId, invitedById: uid(req), email, phone, phoneKey: pKey, role: b.role, status: 'ACCEPTED', respondedAt: new Date() },
      });
      void notifyUser(target.id, {
        title: target.locale === 'he' ? `👶 הצטרפת למעקב אחרי ${baby.name}` : `👶 Following ${baby.name}`,
        body: target.locale === 'he'
          ? `${me.name} הוסיף/ה אותך כ${b.role === 'CAREGIVER' ? 'מטפל/ת' : 'צופה'} עבור ${baby.name}.`
          : `${me.name} added you as a ${b.role === 'CAREGIVER' ? 'Caregiver' : 'Viewer'} for ${baby.name}.`,
        babyId,
        data: { type: 'member_joined', role: b.role },
      }).catch((e) => req.log.error(e));
    } else {
      // No account yet -> pending invitation, auto-accepted when they register with this email/phone.
      const existing = await prisma.invitation.findFirst({
        where: { babyId, status: 'PENDING', OR: [...(email ? [{ email }] : []), ...(pKey ? [{ phoneKey: pKey }] : [])] },
      });
      invitation = existing
        ? await prisma.invitation.update({ where: { id: existing.id }, data: { role: b.role } })
        : await prisma.invitation.create({
            data: { babyId, invitedById: uid(req), email, phone, phoneKey: pKey, role: b.role, status: 'PENDING' },
          });
    }

    // Email (nice template). SMS is intentionally disabled for now.
    const mailTo = email ?? (target && !target.email.endsWith('@placeholder.local') ? target.email : null);
    let emailSent = false;
    let emailError: string | undefined;
    if (mailTo) {
      const r = await sendInviteEmail({
        to: mailTo,
        inviterName: me.name,
        babyName: baby.name,
        role: b.role === 'VIEWER' ? 'VIEWER' : 'CAREGIVER',
        locale: target?.locale ?? me.locale ?? 'en',
        hasAccount: !!target,
      });
      emailSent = r.sent;
      emailError = r.error;
      req.log.info(`[INVITE EMAIL ${r.sent ? 'SENT' : 'NOT SENT'} to ${mailTo}] ${r.error ?? ''}`);
    }

    const link = `${env.APP_URL}/?invite=1${email ? `&email=${encodeURIComponent(email)}` : ''}`;
    const shareText = `🍼 ${me.name} → BabyDaily: ${baby.name}\n${link}`;
    return reply.code(201).send({
      invitation,
      member,
      userExists: !!target,
      memberAdded: !!member,
      emailSent,
      emailError,
      inviteLink: link,
      whatsappUrl: `https://wa.me/${phone ? phone.replace(/\D/g, '') : ''}?text=${encodeURIComponent(shareText)}`,
      telegramUrl: `https://t.me/share/url?url=${encodeURIComponent(link)}&text=${encodeURIComponent(shareText)}`,
    });
  };

  app.post('/babies/:babyId/invitations', inviteHandler);
  app.post('/babies/:babyId/invite', inviteHandler);

  app.delete('/invitations/:id', async (req, reply) => {
    const { id } = IdParams.parse(req.params);
    const inv = await prisma.invitation.findUnique({ where: { id } });
    if (!inv) throw notFound('invitation_not_found');
    await requireMember(inv.babyId, uid(req), 'OWNER');
    await prisma.invitation.update({ where: { id }, data: { status: 'REVOKED', respondedAt: new Date() } });
    return reply.code(204).send();
  });

  // ---------- Invitations (invitee side) ----------
  async function myInviteFilter(userId: string) {
    const me = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return { me, or: [{ email: me.email }, ...(me.phoneKey ? [{ phoneKey: me.phoneKey }] : [])] };
  }

  app.get('/invitations', async (req) => {
    const { or } = await myInviteFilter(uid(req));
    return prisma.invitation.findMany({
      where: { status: 'PENDING', OR: or },
      include: {
        baby: { select: { id: true, name: true, avatarColor: true, birthDate: true } },
        invitedBy: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  });

  async function loadMine(id: string, userId: string) {
    const { me, or } = await myInviteFilter(userId);
    const inv = await prisma.invitation.findFirst({ where: { id, status: 'PENDING', OR: or } });
    if (!inv) throw notFound('invitation_not_found');
    return { me, inv };
  }

  app.post('/invitations/:id/accept', async (req) => {
    const { id } = IdParams.parse(req.params);
    const { me, inv } = await loadMine(id, uid(req));

    await prisma.$transaction([
      prisma.babyMember.upsert({
        where: { babyId_userId: { babyId: inv.babyId, userId: me.id } },
        create: { babyId: inv.babyId, userId: me.id, role: inv.role },
        update: {},
      }),
      prisma.invitation.update({ where: { id }, data: { status: 'ACCEPTED', respondedAt: new Date() } }),
    ]);

    const [baby, inviter] = await Promise.all([
      prisma.baby.findUniqueOrThrow({ where: { id: inv.babyId } }),
      prisma.user.findUnique({ where: { id: inv.invitedById } }),
    ]);
    if (inviter) {
      void notifyUser(inviter.id, {
        ...t.inviteAccepted(inviter.locale, me.name, baby.name),
        babyId: baby.id,
        data: { type: 'member_joined' },
      }).catch((e) => req.log.error(e));
    }
    return { ...baby, role: inv.role };
  });

  app.post('/invitations/:id/decline', async (req, reply) => {
    const { id } = IdParams.parse(req.params);
    await loadMine(id, uid(req));
    await prisma.invitation.update({ where: { id }, data: { status: 'DECLINED', respondedAt: new Date() } });
    return reply.code(204).send();
  });

  // ---------- Members ----------
  app.patch('/babies/:babyId/members/:memberId', async (req) => {
    const { babyId, memberId } = MemberParams.parse(req.params);
    await requireMember(babyId, uid(req), 'OWNER');
    const { role } = MemberPatchBody.parse(req.body);
    const target = await prisma.babyMember.findFirst({ where: { id: memberId, babyId } });
    if (!target) throw notFound('member_not_found');
    if (target.role === 'OWNER' && role !== 'OWNER') {
      const owners = await prisma.babyMember.count({ where: { babyId, role: 'OWNER' } });
      if (owners <= 1) throw badRequest('last_owner');
    }
    return prisma.babyMember.update({
      where: { id: memberId },
      data: { role },
      select: { id: true, role: true, createdAt: true, user: { select: publicUserSelect } },
    });
  });

  app.delete('/babies/:babyId/members/:memberId', async (req, reply) => {
    const { babyId, memberId } = MemberParams.parse(req.params);
    const me = await requireMember(babyId, uid(req));
    const target = await prisma.babyMember.findFirst({ where: { id: memberId, babyId } });
    if (!target) throw notFound('member_not_found');
    const isSelf = target.userId === uid(req);
    if (!isSelf && me.role !== 'OWNER') throw forbidden('insufficient_role');
    if (target.role === 'OWNER') {
      const owners = await prisma.babyMember.count({ where: { babyId, role: 'OWNER' } });
      if (owners <= 1) throw badRequest('last_owner');
    }
    await prisma.$transaction([
      prisma.reminder.deleteMany({ where: { babyId, userId: target.userId } }),
      prisma.babyMember.delete({ where: { id: memberId } }),
    ]);
    return reply.code(204).send();
  });

  // ---------- My notification settings for a baby ----------
  app.get('/babies/:babyId/settings', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const m = await requireMember(babyId, uid(req));
    return { notifyEnabled: m.notifyEnabled, notifyTypes: m.notifyTypes, quietStart: m.quietStart, quietEnd: m.quietEnd };
  });

  app.put('/babies/:babyId/settings', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const m = await requireMember(babyId, uid(req));
    const b = SettingsBody.parse(req.body);
    const u = await prisma.babyMember.update({ where: { id: m.id }, data: b });
    return { notifyEnabled: u.notifyEnabled, notifyTypes: u.notifyTypes, quietStart: u.quietStart, quietEnd: u.quietEnd };
  });
}
