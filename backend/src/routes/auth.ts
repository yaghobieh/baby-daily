import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import { prisma } from '../db.js';
import { badRequest, conflict, notFound, unauthorized } from '../lib/errors.js';
import { normalizeEmail, normalizePhone, phoneKey } from '../lib/contact.js';
import { toUserDto, uid } from '../lib/http.js';
import { ForgotPasswordBody, GoogleAuthBody, LoginBody, RegisterBody, ResetPasswordBody, UpdateMeBody } from '../schemas.js';
import { notifyUser } from '../services/notify.js';
import { sendPasswordResetEmail, sendWelcomeEmail } from '../services/email.js';

export default async function authRoutes(app: FastifyInstance) {
  const sign = (userId: string) => app.jwt.sign({ sub: userId }, { expiresIn: '60d' });

  app.post('/auth/register', async (req, reply) => {
    const b = RegisterBody.parse(req.body);
    const email = normalizeEmail(b.email)!;
    const rawPKey = phoneKey(b.phone);

    // Avoid P2002 unique constraint failure if phoneKey already belongs to another account
    let safePKey: string | null = rawPKey;
    if (rawPKey) {
      const phoneOwner = await prisma.user.findUnique({ where: { phoneKey: rawPKey } });
      if (phoneOwner && phoneOwner.email !== email) {
        safePKey = null;
      }
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    let user;
    if (existing) {
      user = await prisma.user.update({
        where: { id: existing.id },
        data: {
          name: b.name,
          phone: normalizePhone(b.phone) ?? existing.phone,
          phoneKey: safePKey ?? existing.phoneKey,
          passwordHash: await bcrypt.hash(b.password, 11),
          locale: b.locale ?? existing.locale ?? 'en',
          utcOffset: b.utcOffset ?? existing.utcOffset ?? 0,
        },
      });
    } else {
      user = await prisma.user.create({
        data: {
          name: b.name,
          email,
          phone: normalizePhone(b.phone),
          phoneKey: safePKey,
          passwordHash: await bcrypt.hash(b.password, 11),
          locale: b.locale ?? 'en',
          utcOffset: b.utcOffset ?? 0,
        },
      });
    }
    const pKey = safePKey;

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

  // Proxy for google_sign_in_web's People API call using standard OIDC userinfo
  app.get('/auth/google/people-proxy', async (req, reply) => {
    const authHeader = req.headers.authorization;
    const queryToken = typeof (req.query as any)?.access_token === 'string' ? (req.query as any).access_token : null;
    const bearer = authHeader || (queryToken ? `Bearer ${queryToken}` : '');
    if (!bearer) {
      return reply.code(401).send({ error: 'unauthorized' });
    }
    const r = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: { Authorization: bearer },
    });
    if (!r.ok) {
      const txt = await r.text();
      return reply.code(r.status).send(txt);
    }
    const u = (await r.json()) as {
      sub?: string;
      name?: string;
      given_name?: string;
      family_name?: string;
      email?: string;
      picture?: string;
    };
    return {
      resourceName: `people/${u.sub || 'me'}`,
      names: [
        {
          metadata: { primary: true },
          displayName: u.name || u.email || 'Parent',
          givenName: u.given_name || '',
          familyName: u.family_name || '',
        },
      ],
      emailAddresses: [
        {
          metadata: { primary: true },
          value: u.email || '',
        },
      ],
      photos: u.picture
        ? [
            {
              metadata: { primary: true },
              url: u.picture,
            },
          ]
        : [],
    };
  });

  app.post('/auth/google', async (req) => {
    const b = GoogleAuthBody.parse(req.body);
    let rawEmail = b.email;
    let googleName = b.name?.trim();

    // If a Google OAuth accessToken or idToken was provided, verify with Google
    if (b.accessToken) {
      const res = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${b.accessToken}` },
      });
      if (res.ok) {
        const info = (await res.json()) as { email?: string; name?: string };
        if (info.email) rawEmail = info.email;
        if (info.name && !googleName) googleName = info.name;
      }
    } else if (b.idToken) {
      const res = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(b.idToken)}`);
      if (res.ok) {
        const info = (await res.json()) as { email?: string; name?: string };
        if (info.email) rawEmail = info.email;
        if (info.name && !googleName) googleName = info.name;
      }
    }

    const email = normalizeEmail(rawEmail);
    if (!email) throw badRequest('email_required');

    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      const defaultName = googleName || email.split('@')[0] || 'Parent';
      user = await prisma.user.create({
        data: {
          name: defaultName,
          email,
          passwordHash: await bcrypt.hash(`google_${Date.now()}_${Math.random()}`, 11),
          locale: b.locale ?? 'en',
          utcOffset: b.utcOffset ?? 0,
        },
      });

      // Auto-claim any pending invitations for this email
      const pendingInvites = await prisma.invitation.findMany({
        where: { status: 'PENDING', email },
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
      }

      // Ensure user has at least one baby profile
      const memberCount = await prisma.babyMember.count({ where: { userId: user.id } });
      if (memberCount === 0) {
        await prisma.baby.create({
          data: {
            name: (b.locale ?? 'en') === 'he' ? 'התינוק/ת שלי' : 'My Baby',
            birthDate: new Date(),
            gender: 'boy',
            avatarColor: '#FF7A7A',
            members: {
              create: { userId: user.id, role: 'OWNER', notifyEnabled: true },
            },
          },
        });
      }
    } else if (b.utcOffset != null && b.utcOffset !== user.utcOffset) {
      user = await prisma.user.update({ where: { id: user.id }, data: { utcOffset: b.utcOffset } });
    }

    return { token: sign(user.id), user: toUserDto(user) };
  });

  app.post('/auth/forgot-password', async (req) => {
    const b = ForgotPasswordBody.parse(req.body);
    const isEmail = b.identifier.includes('@');
    const user = isEmail
      ? await prisma.user.findUnique({ where: { email: normalizeEmail(b.identifier)! } })
      : await prisma.user.findUnique({ where: { phoneKey: phoneKey(b.identifier) ?? '__none__' } });

    if (user && user.email) {
      const resetToken = app.jwt.sign({ sub: user.id, type: 'reset_password' } as any, { expiresIn: '1h' });
      void sendPasswordResetEmail({
        to: user.email,
        name: user.name,
        resetToken,
        locale: user.locale,
      }).catch((e) => req.log.error(e));
    }

    return { success: true, message: 'If an account exists with this detail, a password reset email was sent.' };
  });

  app.post('/auth/reset-password', async (req) => {
    const b = ResetPasswordBody.parse(req.body);
    let payload: { sub: string; type?: string };
    try {
      payload = app.jwt.verify(b.token) as { sub: string; type?: string };
    } catch {
      throw badRequest('invalid_or_expired_token');
    }

    if (payload.type !== 'reset_password' || !payload.sub) {
      throw badRequest('invalid_token_type');
    }

    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) throw notFound('user_not_found');

    const passwordHash = await bcrypt.hash(b.password, 11);
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    return { success: true, message: 'Password has been reset successfully.' };
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
