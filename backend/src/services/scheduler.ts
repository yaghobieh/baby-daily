import type { Entry, EntryType, Reminder } from '@prisma/client';
import { prisma } from '../db.js';
import { t } from '../lib/i18n.js';
import { notifyUser } from './notify.js';

const DAY = 86_400_000;

/** Next UTC instant for a local time-of-day (minutes from midnight) given a UTC offset in minutes. */
export function nextDaily(timeOfDay: number, utcOffset: number, from = new Date()): Date {
  const localNow = new Date(from.getTime() + utcOffset * 60_000);
  const localMidnightUtc = Date.UTC(localNow.getUTCFullYear(), localNow.getUTCMonth(), localNow.getUTCDate());
  let t = localMidnightUtc + timeOfDay * 60_000 - utcOffset * 60_000;
  if (t <= from.getTime()) t += DAY;
  return new Date(t);
}

/** The moment an AFTER_LAST reminder counts from: wake-up time for sleep, start time otherwise. */
function anchorOf(e: Pick<Entry, 'type' | 'startedAt' | 'endedAt'>) {
  return e.type === 'SLEEP' && e.endedAt ? e.endedAt : e.startedAt;
}

/** Computes nextAt for a reminder from current data. */
export async function computeNextAt(r: Reminder): Promise<Date | null> {
  if (!r.enabled) return null;
  if (r.kind === 'DAILY_AT') return r.timeOfDay == null ? null : nextDaily(r.timeOfDay, r.utcOffset);
  if (!r.entryType || !r.intervalMinutes) return null;
  const last = await prisma.entry.findFirst({
    where: { babyId: r.babyId, type: r.entryType },
    orderBy: { startedAt: 'desc' },
  });
  if (!last) return null;
  if (last.type === 'SLEEP' && !last.endedAt) return null; // still sleeping
  const at = new Date(anchorOf(last).getTime() + r.intervalMinutes * 60_000);
  return at > new Date() ? at : null;
}

/** Re-arms AFTER_LAST reminders whenever an entry of that type is created/updated. */
export async function rescheduleAfterEntry(babyId: string, type: EntryType) {
  const reminders = await prisma.reminder.findMany({
    where: { babyId, entryType: type, kind: 'AFTER_LAST', enabled: true },
  });
  await Promise.all(
    reminders.map(async (r) => prisma.reminder.update({ where: { id: r.id }, data: { nextAt: await computeNextAt(r) } })),
  );
}

let running = false;

export async function tick() {
  if (running) return;
  running = true;
  try {
    const due = await prisma.reminder.findMany({
      where: { enabled: true, nextAt: { lte: new Date() } },
      include: { baby: { select: { name: true } }, user: { select: { locale: true } } },
      take: 200,
    });
    for (const r of due) {
      const msg = t.reminder(r.user.locale, r.title, r.baby.name);
      await notifyUser(r.userId, { ...msg, babyId: r.babyId, data: { type: 'reminder', reminderId: r.id } });
      await prisma.reminder.update({
        where: { id: r.id },
        data: {
          lastFiredAt: new Date(),
          nextAt: r.kind === 'DAILY_AT' && r.timeOfDay != null ? nextDaily(r.timeOfDay, r.utcOffset) : null,
        },
      });
    }
  } catch (err) {
    console.error('reminder tick failed', err);
  } finally {
    running = false;
  }
}

export function startScheduler() {
  setInterval(tick, 30_000).unref();
  void tick();
}
