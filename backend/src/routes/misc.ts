import type { FastifyInstance } from 'fastify';
import { prisma } from '../db.js';
import { requireMember } from '../lib/access.js';
import { badRequest, notFound } from '../lib/errors.js';
import { uid } from '../lib/http.js';
import { BabyParams, DeviceBody, IdParams, PhotoBody, ReminderBody, TestNotifyBody } from '../schemas.js';
import { computeNextAt } from '../services/scheduler.js';
import { normalizePhone, phoneKey } from '../lib/contact.js';
import { notifyUser } from '../services/notify.js';
import { z } from 'zod';

const MAX_PHOTO_BYTES = 4 * 1024 * 1024;

/** Reminders, notifications inbox, device tokens, photos. */
export default async function miscRoutes(app: FastifyInstance) {
  app.addHook('onRequest', async (req) => {
    if (req.url.startsWith('/notifications/test')) return;
    await app.authenticate(req);
  });

  // ---------- Reminders (personal, per baby) ----------
  app.get('/babies/:babyId/reminders', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    return prisma.reminder.findMany({ where: { babyId, userId: uid(req) }, orderBy: { createdAt: 'asc' } });
  });

  app.post('/babies/:babyId/reminders', async (req, reply) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    const b = ReminderBody.parse(req.body);
    const created = await prisma.reminder.create({
      data: {
        babyId,
        userId: uid(req),
        kind: b.kind,
        title: b.title,
        entryType: b.kind === 'AFTER_LAST' ? b.entryType! : null,
        intervalMinutes: b.kind === 'AFTER_LAST' ? b.intervalMinutes! : null,
        timeOfDay: b.kind === 'DAILY_AT' ? b.timeOfDay! : null,
        utcOffset: b.utcOffset,
        enabled: b.enabled,
      },
    });
    const r = await prisma.reminder.update({ where: { id: created.id }, data: { nextAt: await computeNextAt(created) } });
    return reply.code(201).send(r);
  });

  async function myReminder(id: string, userId: string) {
    const r = await prisma.reminder.findFirst({ where: { id, userId } });
    if (!r) throw notFound('reminder_not_found');
    return r;
  }

  app.patch('/reminders/:id', async (req) => {
    const { id } = IdParams.parse(req.params);
    const existing = await myReminder(id, uid(req));
    const merged = ReminderBody.parse({ ...existing, ...(req.body as object) });
    const updated = await prisma.reminder.update({
      where: { id },
      data: {
        kind: merged.kind,
        title: merged.title,
        entryType: merged.kind === 'AFTER_LAST' ? merged.entryType! : null,
        intervalMinutes: merged.kind === 'AFTER_LAST' ? merged.intervalMinutes! : null,
        timeOfDay: merged.kind === 'DAILY_AT' ? merged.timeOfDay! : null,
        utcOffset: merged.utcOffset,
        enabled: merged.enabled,
      },
    });
    return prisma.reminder.update({ where: { id }, data: { nextAt: await computeNextAt(updated) } });
  });

  app.delete('/reminders/:id', async (req, reply) => {
    const { id } = IdParams.parse(req.params);
    await myReminder(id, uid(req));
    await prisma.reminder.delete({ where: { id } });
    return reply.code(204).send();
  });

  // ---------- Notifications inbox ----------
  app.get('/notifications', async (req) => {
    const q = z
      .object({ limit: z.coerce.number().int().min(1).max(100).default(50), before: z.coerce.date().optional() })
      .parse(req.query);
    return prisma.notification.findMany({
      where: { userId: uid(req), ...(q.before ? { createdAt: { lt: q.before } } : {}) },
      orderBy: { createdAt: 'desc' },
      take: q.limit,
    });
  });

  app.get('/notifications/unread-count', async (req) => ({
    count: await prisma.notification.count({ where: { userId: uid(req), readAt: null } }),
  }));

  app.post('/notifications/read-all', async (req) => {
    const r = await prisma.notification.updateMany({ where: { userId: uid(req), readAt: null }, data: { readAt: new Date() } });
    return { updated: r.count };
  });

  app.post('/notifications/:id/read', async (req) => {
    const { id } = IdParams.parse(req.params);
    await prisma.notification.updateMany({ where: { id, userId: uid(req) }, data: { readAt: new Date() } });
    return { ok: true };
  });

  app.post('/notifications/test', async (req, reply) => {
    let targetUserId: string | null = null;
    try {
      if (req.headers.authorization) {
        await app.authenticate(req);
        targetUserId = uid(req);
      }
    } catch (_) {}

    const b = TestNotifyBody.parse(req.body ?? {});
    let targetPhone = b.phone ? normalizePhone(b.phone) ?? b.phone : '';

    if (b.phone) {
      const pKey = phoneKey(b.phone);
      if (pKey) {
        const u = await prisma.user.findUnique({ where: { phoneKey: pKey } });
        if (u) {
          targetUserId = u.id;
          targetPhone = u.phone ?? targetPhone;
        }
      }
    }

    const title = b.title ?? '🔔 BabyDaily Test Notification';
    const body = b.body ?? `שלום! התראת בדיקה נשלחה בהצלחה למכשיר שלך (${targetPhone || 'חשבון קיים'}).`;

    if (targetUserId) {
      await notifyUser(targetUserId, {
        title,
        body,
        data: { type: 'test' },
      });
    }

    // Clean phone for WhatsApp
    const waDigits = targetPhone.replace(/\D/g, '');
    const encodedText = encodeURIComponent(`${title}\n${body}`);
    const whatsappUrl = waDigits ? `https://wa.me/${waDigits}?text=${encodedText}` : `https://wa.me/?text=${encodedText}`;
    const telegramUrl = `https://t.me/share/url?text=${encodedText}`;

    req.log.info(`[TEST NOTIFICATION SENT via ${b.channel}]: Phone: ${targetPhone || 'in-app'}, WhatsApp: ${whatsappUrl}, Telegram: ${telegramUrl}`);

    return {
      ok: true,
      sentToUserId: targetUserId,
      phone: targetPhone,
      channel: b.channel,
      title,
      body,
      whatsappUrl,
      telegramUrl,
      delivered: {
        push: !!targetUserId,
        sms: !!targetPhone,
        whatsapp: true,
        telegram: true,
      },
    };
  });

  // ---------- Device tokens (FCM) ----------
  app.post('/devices', async (req) => {
    const b = DeviceBody.parse(req.body);
    await prisma.deviceToken.upsert({
      where: { token: b.token },
      create: { token: b.token, platform: b.platform, userId: uid(req) },
      update: { userId: uid(req), platform: b.platform },
    });
    return { ok: true };
  });

  app.delete('/devices', async (req) => {
    const { token } = z.object({ token: z.string() }).parse(req.body);
    await prisma.deviceToken.deleteMany({ where: { token, userId: uid(req) } });
    return { ok: true };
  });

  // ---------- Photos ----------
  app.post('/babies/:babyId/photos', async (req, reply) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req), 'CAREGIVER');
    const b = PhotoBody.parse(req.body);
    const bytes = Buffer.from(b.data, 'base64');
    if (bytes.length > MAX_PHOTO_BYTES) throw badRequest('photo_too_large');
    const p = await prisma.photo.create({ data: { babyId, mime: b.mime, bytes }, select: { id: true } });
    return reply.code(201).send(p);
  });

  app.get('/photos/:id', async (req, reply) => {
    const { id } = IdParams.parse(req.params);
    const p = await prisma.photo.findUnique({ where: { id } });
    if (!p) throw notFound('photo_not_found');
    await requireMember(p.babyId, uid(req));
    reply.header('Cache-Control', 'private, max-age=31536000, immutable');
    return { id: p.id, mime: p.mime, data: Buffer.from(p.bytes).toString('base64') };
  });
}
