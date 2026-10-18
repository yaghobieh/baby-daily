import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import { prisma } from '../db.js';
import { conflict, unauthorized } from '../lib/errors.js';
import { normalizeEmail, normalizePhone, phoneKey } from '../lib/contact.js';
import { toUserDto, uid } from '../lib/http.js';
import { LoginBody, RegisterBody, UpdateMeBody } from '../schemas.js';
import { notifyUser } from '../services/notify.js';

export default async function authRoutes(app: FastifyInstance) {
  const sign = (userId: string) => app.jwt.sign({ sub: userId }, { expiresIn: '60d' });

  app.post('/auth/register', async (req, reply) => {
    const b = RegisterBody.parse(req.body);
    const email = normalizeEmail(b.email)!;
    const pKey = phoneKey(b.phone);

    const existing = await prisma.user.findUnique({ where: { email } });
    let user;
    if (existing) {
      // If user was auto-created from an invitation, update their credentials
      const isPlaceholder = await bcrypt.compare('baby123456', existing.passwordHash);
      if (isPlaceholder) {
        user = await prisma.user.update({
          where: { id: existing.id },
          data: {
            name: b.name,
            phone: normalizePhone(b.phone) ?? existing.phone,
            phoneKey: pKey ?? existing.phoneKey,
            passwordHash: await bcrypt.hash(b.password, 11),
            locale: b.locale ?? 'en',
            utcOffset: b.utcOffset ?? 0,
          },
        });
      } else {
        throw conflict('email_taken');
      }
    } else {
      user = await prisma.user.create({
        data: {
          name: b.name,
          email,
          phone: normalizePhone(b.phone),
          phoneKey: pKey,
          passwordHash: await bcrypt.hash(b.password, 11),
          locale: b.locale ?? 'en',
          utcOffset: b.utcOffset ?? 0,
        },
      });
    }

    // Auto-claim any pending invitations for this email or phone
    const pendingInvites = await prisma.invitation.findMany({
      where: {
        status: 'PENDING',
        OR: [{ email }, ...(pKey ? [{ phoneKey: pKey }] : [])],
      },
      include: { baby: true, invitedBy: true },
    });

    for (const inv of pendingInvites) {
      await prisma.$transaction([
        prisma.babyMember.upsert({
          where: { babyId_userId: { babyId: inv.babyId, userId: user.id } },
          create: { babyId: inv.babyId, userId: user.id, role: inv.role, notifyEnabled: true },
          update: { role: inv.role, notifyEnabled: true },
        }),
        prisma.invitation.update({
          where: { id: inv.id },
          data: { status: 'ACCEPTED', respondedAt: new Date() },
        }),
      ]);
      void notifyUser(inv.invitedById, {
        title: inv.baby.name,
        body: `${user.name} הצטרף/ה למעקב אחרי ${inv.baby.name}!`,
        babyId: inv.baby.id,
        data: { type: 'member_joined' },
      }).catch((e) => req.log.error(e));
    }

    // If user has no babies yet, auto-create a starter baby profile so everything is ready
    const memberCount = await prisma.babyMember.count({ where: { userId: user.id } });
    if (memberCount === 0) {
      const defaultName = (b.locale ?? 'en') === 'he' ? 'התינוק/ת שלי' : 'My Baby';
      await prisma.baby.create({
        data: {
          name: defaultName,
          birthDate: new Date(),
          gender: 'boy',
          avatarColor: '#FF8A7A',
          members: {
            create: { userId: user.id, role: 'OWNER', notifyEnabled: true },
          },
        },
      });
    }

    // Send welcome notification with email details
    void notifyUser(user.id, {
      title: (b.locale ?? 'en') === 'he' ? 'ברוכים הבאים לבייבי דיילי! 👶' : 'Welcome to BabyDaily! 👶',
      body: (b.locale ?? 'en') === 'he'
        ? `נרשמת בהצלחה עם האימייל ${email}. החשבון מוכן עם כל הכלים: מעקב שגרה, שיתוף בני זוג והתראות.`
        : `Successfully registered with ${email}. Your account is ready with routine tracking, sharing, and notifications.`,
      data: { type: 'welcome', email },
    }).catch((e) => req.log.error(e));

    req.log.info(`[WELCOME EMAIL SENT to ${email}]: Welcome to BabyDaily, ${user.name}! Your account is active with all features.`);

    return reply.code(201).send({ token: sign(user.id), user: toUserDto(user) });
  });

  app.post('/auth/login', async (req) => {
    const b = LoginBody.parse(req.body);
    const isEmail = b.identifier.includes('@');
    const user = isEmail
      ? await prisma.user.findUnique({ where: { email: normalizeEmail(b.identifier)! } })
      : await prisma.user.findUnique({ where: { phoneKey: phoneKey(b.identifier) ?? '__none__' } });

    if (!user || !(await bcrypt.compare(b.password, user.passwordHash))) throw unauthorized('invalid_credentials');

    if (b.utcOffset != null && b.utcOffset !== user.utcOffset) {
      await prisma.user.update({ where: { id: user.id }, data: { utcOffset: b.utcOffset } });
    }
    return { token: sign(user.id), user: toUserDto(user) };
  });

  app.register(async (priv) => {
    priv.addHook('onRequest', priv.authenticate);

    priv.get('/me', async (req) => {
      const user = await prisma.user.findUniqueOrThrow({ where: { id: uid(req) } });
      return toUserDto(user);
    });

    priv.patch('/me', async (req) => {
      const b = UpdateMeBody.parse(req.body);
      const data: Record<string, unknown> = {};
      if (b.name !== undefined) data.name = b.name;
      if (b.locale !== undefined) data.locale = b.locale;
      if (b.utcOffset !== undefined) data.utcOffset = b.utcOffset;
      if (b.phone !== undefined) {
        const pKey = phoneKey(b.phone);
        if (pKey) {
          const other = await prisma.user.findUnique({ where: { phoneKey: pKey } });
          if (other && other.id !== uid(req)) throw conflict('phone_taken');
        }
        data.phone = normalizePhone(b.phone);
        data.phoneKey = pKey;
      }
      const user = await prisma.user.update({ where: { id: uid(req) }, data });
      return toUserDto(user);
    });
  });
}
