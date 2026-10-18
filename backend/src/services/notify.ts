import { cert, initializeApp, type App } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';
import type { EntryType, Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import { env } from '../env.js';

let messaging: Messaging | null = null;

/** Initializes FCM if credentials are configured. Without them, only in-app notifications are stored. */
export function initPush(log: { info: (m: string) => void; warn: (m: string) => void }) {
  if (!env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    log.warn('FCM disabled: FIREBASE_SERVICE_ACCOUNT_BASE64 not set (in-app notifications still work)');
    return;
  }
  try {
    const json = JSON.parse(Buffer.from(env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8'));
    const app: App = initializeApp({ credential: cert(json) });
    messaging = getMessaging(app);
    log.info('FCM push notifications enabled');
  } catch (err) {
    log.warn(`FCM init failed: ${(err as Error).message}`);
  }
}

export interface NotifyPayload {
  title: string;
  body: string;
  babyId?: string;
  data?: Record<string, string>;
  /** If false, store in-app only (e.g. during quiet hours). */
  push?: boolean;
}

/** Stores an in-app notification and sends a push to every registered device of the user. */
export async function notifyUser(userId: string, p: NotifyPayload) {
  await prisma.notification.create({
    data: {
      userId,
      babyId: p.babyId ?? null,
      title: p.title,
      body: p.body,
      data: (p.data ?? {}) as Prisma.InputJsonValue,
    },
  });
  if (p.push === false || !messaging) return;

  const devices = await prisma.deviceToken.findMany({ where: { userId } });
  if (!devices.length) return;

  try {
    const res = await messaging.sendEachForMulticast({
      tokens: devices.map((d) => d.token),
      notification: { title: p.title, body: p.body },
      data: { ...(p.data ?? {}), ...(p.babyId ? { babyId: p.babyId } : {}) },
      android: { priority: 'high', notification: { channelId: 'baby_daily', sound: 'default' } },
      apns: { payload: { aps: { sound: 'default' } } },
      webpush: { notification: { icon: '/icons/Icon-192.png' } },
    });
    // Clean up dead tokens
    const dead: string[] = [];
    res.responses.forEach((r, i) => {
      const code = r.error?.code ?? '';
      if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
        dead.push(devices[i]!.token);
      }
    });
    if (dead.length) await prisma.deviceToken.deleteMany({ where: { token: { in: dead } } });
  } catch (err) {
    console.warn('FCM send failed', (err as Error).message);
  }
}

/** True if `now` falls inside the [start,end) local quiet window (supports windows crossing midnight). */
export function inQuietHours(start: number | null, end: number | null, utcOffset: number, now = new Date()) {
  if (start == null || end == null || start === end) return false;
  const utcMin = now.getUTCHours() * 60 + now.getUTCMinutes();
  const local = (((utcMin + utcOffset) % 1440) + 1440) % 1440;
  return start < end ? local >= start && local < end : local >= start || local < end;
}

/**
 * Fan-out to every member of a baby (except the actor) who opted in to this entry type.
 * `build` receives the recipient locale so each person gets text in their language.
 */
export async function notifyBabyMembers(opts: {
  babyId: string;
  exceptUserId: string;
  entryType?: EntryType;
  build: (locale: string) => { title: string; body: string };
  data?: Record<string, string>;
}) {
  const members = await prisma.babyMember.findMany({
    where: { babyId: opts.babyId, userId: { not: opts.exceptUserId }, notifyEnabled: true },
    include: { user: { select: { id: true, locale: true, utcOffset: true } } },
  });

  await Promise.all(
    members
      .filter((m) => !opts.entryType || m.notifyTypes.includes(opts.entryType))
      .map((m) => {
        const { title, body } = opts.build(m.user.locale);
        const quiet = inQuietHours(m.quietStart, m.quietEnd, m.user.utcOffset);
        return notifyUser(m.userId, { title, body, babyId: opts.babyId, data: opts.data, push: !quiet });
      }),
  );
}
