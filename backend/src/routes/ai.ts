import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db.js';
import { env } from '../env.js';
import { requireMember } from '../lib/access.js';
import { HttpError } from '../lib/errors.js';
import { toUserDto, uid } from '../lib/http.js';
import { BabyParams } from '../schemas.js';
import { sendEmail } from '../services/email.js';
import { notifyUser } from '../services/notify.js';

const FREE_DAILY_AI_LIMIT = 3;

const ChatBody = z.object({
  message: z.string().trim().min(1).max(1200),
  locale: z.string().optional(),
});

const DailySummaryBody = z.object({
  sendToEmail: z.boolean().optional().default(true),
  sendNotification: z.boolean().optional().default(true),
  locale: z.string().optional(),
});

const StatsQuery = z.object({
  days: z.coerce.number().int().min(1).max(30).default(7),
});

const SubscriptionBody = z.object({
  plan: z.enum(['FREE', 'MONTHLY', 'YEARLY', 'LIFETIME']),
  dailySummaryEmail: z.boolean().optional(),
});

function calculateAgeText(birthDate: Date | null, he = false): string {
  if (!birthDate) return he ? 'גיל לא הוגדר' : 'Age not specified';
  const diffMs = Date.now() - birthDate.getTime();
  if (diffMs <= 0) return he ? 'ילוד (Newborn)' : 'Newborn';
  const days = Math.floor(diffMs / 86_400_000);
  const weeks = Math.floor(days / 7);
  const months = Math.floor(days / 30.44);
  if (months >= 1) {
    return he ? `${months} חודשים (${weeks} שבועות)` : `${months} months (${weeks} weeks old)`;
  }
  return he ? `${weeks} שבועות (${days} ימים)` : `${weeks} weeks (${days} days old)`;
}

function getRecommendedWakeWindowMinutes(birthDate: Date | null): { min: number; max: number } {
  if (!birthDate) return { min: 75, max: 120 };
  const days = Math.max(0, Math.floor((Date.now() - birthDate.getTime()) / 86_400_000));
  if (days < 30) return { min: 45, max: 60 };
  if (days < 90) return { min: 60, max: 90 };
  if (days < 180) return { min: 90, max: 120 };
  if (days < 270) return { min: 120, max: 180 };
  return { min: 150, max: 240 };
}

async function callDeepSeek(systemPrompt: string, userMessage: string): Promise<string | null> {
  if (!env.DEEPSEEK_API_KEY) return null;
  try {
    const res = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${env.DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage },
        ],
        max_tokens: 450,
        temperature: 0.65,
      }),
    });
    if (!res.ok) return null;
    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    return json.choices?.[0]?.message?.content?.trim() ?? null;
  } catch {
    return null;
  }
}

export default async function aiRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // ---------------- Live AI Suggestions & Routine Insights ----------------
  app.get('/babies/:babyId/ai/insights', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const userId = uid(req);
    await requireMember(babyId, userId);

    const [user, baby, entries] = await Promise.all([
      prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      prisma.baby.findUniqueOrThrow({ where: { id: babyId } }),
      prisma.entry.findMany({
        where: {
          babyId,
          startedAt: { gte: new Date(Date.now() - 48 * 3600_000) },
        },
        orderBy: { startedAt: 'desc' },
        take: 80,
      }),
    ]);

    const he = user.locale === 'he';
    const now = Date.now();
    const todayStart = new Date(now - 24 * 3600_000);
    const todayEntries = entries.filter((e) => e.startedAt >= todayStart);

    const activeSleep = entries.find((e) => e.type === 'SLEEP' && e.endedAt === null) ?? null;
    const lastCompletedSleep = entries.find((e) => e.type === 'SLEEP' && e.endedAt !== null) ?? null;
    const lastFeed = entries.find((e) => e.type === 'FEED') ?? null;
    const lastDiaper = entries.find((e) => e.type === 'DIAPER') ?? null;

    const awakeMinutes = activeSleep
      ? 0
      : lastCompletedSleep?.endedAt
        ? Math.max(0, Math.round((now - lastCompletedSleep.endedAt.getTime()) / 60_000))
        : null;

    const minutesSinceLastFeed = lastFeed
      ? Math.max(0, Math.round((now - lastFeed.startedAt.getTime()) / 60_000))
      : null;

    const wakeWindow = getRecommendedWakeWindowMinutes(baby.birthDate);

    const suggestions: Array<{
      id: string;
      type: 'SLEEP' | 'FEED' | 'DIAPER' | 'SUMMARY';
      priority: 'HIGH' | 'NORMAL' | 'INFO';
      icon: string;
      title: string;
      body: string;
    }> = [];

    if (activeSleep) {
      const sleepingMin = Math.max(1, Math.round((now - activeSleep.startedAt.getTime()) / 60_000));
      suggestions.push({
        id: 'sleep-active',
        type: 'SLEEP',
        priority: 'INFO',
        icon: '🌙',
        title: he ? `${baby.name} ישן/ה כעת (${sleepingMin} דק׳)` : `${baby.name} is sleeping (${sleepingMin}m)`,
        body: he
          ? 'הטיימר פועל בזמן אמת. לחצ/י על "התעורר/ה" כשהתנומה מסתיימת לעדכון חלון הערות.'
          : 'Live sleep tracker is active. Tap "Wake" when the nap ends to calculate the next sweet-spot wake window.',
      });
    } else if (awakeMinutes !== null) {
      if (awakeMinutes >= wakeWindow.max) {
        suggestions.push({
          id: 'wake-window-alert',
          type: 'SLEEP',
          priority: 'HIGH',
          icon: '😴',
          title: he
            ? `זמן תנומה מומלץ! ער/ה כבר ${awakeMinutes} דק׳`
            : `Sweet-Spot Nap Window! Awake for ${awakeMinutes}m`,
          body: he
            ? `לפי הגיל של ${baby.name}, חלון הערות המומלץ הוא ${wakeWindow.min}–${wakeWindow.max} דקות. כדאי להתחיל שגרת הרדמה רגועה.`
            : `Based on ${baby.name}'s age, optimal wake windows are ${wakeWindow.min}–${wakeWindow.max}m. Look for sleepy cues and start winding down.`,
        });
      } else {
        const nextNapIn = Math.max(5, wakeWindow.min - awakeMinutes);
        suggestions.push({
          id: 'wake-window-next',
          type: 'SLEEP',
          priority: 'NORMAL',
          icon: '☀️',
          title: he
            ? `חלון התנומה הבא בעוד ~${nextNapIn} דק׳`
            : `Next Sweet-Spot Nap in ~${nextNapIn}m`,
          body: he
            ? `${baby.name} ער/ה כעת ${awakeMinutes} דקות (מומלץ: ${wakeWindow.min}–${wakeWindow.max} דק׳).`
            : `${baby.name} has been awake for ${awakeMinutes}m (target window: ${wakeWindow.min}–${wakeWindow.max}m).`,
        });
      }
    }

    if (minutesSinceLastFeed !== null) {
      if (minutesSinceLastFeed >= 180) {
        const hrs = (minutesSinceLastFeed / 60).toFixed(1);
        suggestions.push({
          id: 'feed-due',
          type: 'FEED',
          priority: 'HIGH',
          icon: '🍼',
          title: he ? `עברו ${hrs} שעות מהאכלה אחרונה` : `${hrs}h since last feeding`,
          body: he
            ? `מומלץ להציע האכלה בקרוב כדי לשמור על רצף תזונה רגוע.`
            : `Consider offering a feeding soon to keep ${baby.name}'s daytime nutrition on track.`,
        });
      } else {
        const nextFeedMin = Math.max(10, 180 - minutesSinceLastFeed);
        suggestions.push({
          id: 'feed-ok',
          type: 'FEED',
          priority: 'NORMAL',
          icon: '🍼',
          title: he ? `האכלה הבאה משוערת בעוד ~${nextFeedMin} דק׳` : `Next feeding estimated in ~${nextFeedMin}m`,
          body: he
            ? `האכלה אחרונה תועדה לפני ${minutesSinceLastFeed} דקות.`
            : `Last feeding was logged ${minutesSinceLastFeed} minutes ago.`,
        });
      }
    } else {
      suggestions.push({
        id: 'feed-first',
        type: 'FEED',
        priority: 'INFO',
        icon: '🍼',
        title: he ? 'תעדו האכלה ראשונה להיום' : 'Log a feeding to activate live predictions',
        body: he
          ? 'ברגע שתתעדו האכלה, ה-AI יחשב את מרווחי הארוחות הבאות בזמן אמת.'
          : 'Once you log a feeding, AI will automatically predict the next feeding window.',
      });
    }

    const wetToday = todayEntries.filter(
      (e) => e.type === 'DIAPER' && ((e.data as any)?.kind === 'wet' || (e.data as any)?.kind === 'both'),
    ).length;

    suggestions.push({
      id: 'hydration-check',
      type: 'DIAPER',
      priority: 'INFO',
      icon: '🧷',
      title: he ? `${wetToday} חיתולים רטובים ב-24 שעות האחרונות` : `${wetToday} wet diapers in the last 24h`,
      body: he
        ? wetToday >= 5
          ? 'מדד ההידרציה נראה מצוין! המשיכו כך.'
          : 'מעקב אחר 5–6 חיתולים רטובים ביום עוזר לוודא הידרציה תקינה.'
        : wetToday >= 5
          ? 'Hydration indicator looks great today!'
          : 'Tracking 5–6+ wet diapers per 24h is a great indicator of healthy hydration.',
    });

    const dto = toUserDto(user);
    return {
      babyName: baby.name,
      ageText: calculateAgeText(baby.birthDate, he),
      isSleeping: Boolean(activeSleep),
      awakeMinutes,
      minutesSinceLastFeed,
      recommendedWakeWindow: wakeWindow,
      suggestions,
      quota: {
        isPremium: dto.isPremium,
        subscriptionPlan: dto.subscriptionPlan,
        aiQueriesToday: dto.aiQueriesToday,
        aiDailyLimit: dto.aiDailyLimit,
      },
    };
  });

  // ---------------- Context-Aware AI Chat (DeepSeek + Quota) ----------------
  app.post('/babies/:babyId/ai/chat', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const userId = uid(req);
    await requireMember(babyId, userId);
    const body = ChatBody.parse(req.body);

    const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
    const dto = toUserDto(user);
    const todayUtc = new Date().toISOString().slice(0, 10);

    if (!dto.isPremium && dto.aiQueriesToday >= FREE_DAILY_AI_LIMIT) {
      throw new HttpError(
        402,
        'premium_required',
        'Daily free AI limit (3/3) reached. Upgrade to BabyDaily Premium ($4.99/mo) for unlimited AI assistant, daily email summaries, and 7-day analytics.',
      );
    }

    const [baby, recentEntries] = await Promise.all([
      prisma.baby.findUniqueOrThrow({ where: { id: babyId } }),
      prisma.entry.findMany({
        where: { babyId },
        orderBy: { startedAt: 'desc' },
        take: 25,
      }),
    ]);

    const he = (body.locale ?? user.locale) === 'he';
    const logsSummary = recentEntries
      .map((e) => {
        const time = e.startedAt.toISOString().slice(0, 16).replace('T', ' ');
        const end = e.endedAt ? ` -> ${e.endedAt.toISOString().slice(11, 16)}` : ' (ongoing)';
        return `- [${time}${end}] ${e.type}: ${JSON.stringify(e.data)}`;
      })
      .join('\n');

    const systemPrompt = [
      `You are BabyDaily AI, a warm, knowledgeable parenting and baby routine assistant.`,
      `Baby Name: ${baby.name}. Age: ${calculateAgeText(baby.birthDate, false)}. Gender: ${baby.gender ?? 'not specified'}.`,
      `Recent logged events (UTC):\n${logsSummary || 'No entries logged yet.'}`,
      `Guidelines:`,
      `- Answer the parent's question directly, referencing ${baby.name}'s actual logs and times when helpful.`,
      `- Keep your response concise (2 to 4 short paragraphs or bullet points), supportive, and practical.`,
      `- Remind parents gently for medical concerns to consult a pediatrician.`,
      `- Respond in ${he ? 'Hebrew (עברית)' : 'English'}.`,
    ].join('\n');

    let reply = await callDeepSeek(systemPrompt, body.message);
    if (!reply) {
      reply = he
        ? `לפי הנתונים של ${baby.name} (${calculateAgeText(baby.birthDate, true)}), תועדו לאחרונה ${recentEntries.length} רשומות. מומלץ לשמור על חלונות ערות מותאמים לגיל ולשים לב לסימני עייפות מוקדמים. אם תרצו, אוכל להכין עבורכם גם סיכום יומי למייל!`
        : `Based on ${baby.name}'s recent routine (${calculateAgeText(baby.birthDate, false)}, ${recentEntries.length} recent logs), keeping consistent wake windows and feeding intervals helps build smooth sleep habits. Let me know if you'd like a full summary of today's routine!`;
    }

    const newCount = dto.aiQueriesToday + 1;
    await prisma.user.update({
      where: { id: userId },
      data: {
        aiQueriesToday: newCount,
        aiLastQueryDate: todayUtc,
      },
    });

    return {
      reply,
      aiQueriesToday: newCount,
      aiDailyLimit: dto.isPremium ? 9999 : FREE_DAILY_AI_LIMIT,
      isPremium: dto.isPremium,
    };
  });

  // ---------------- AI Daily Summary -> Notification & Email ----------------
  app.post('/babies/:babyId/ai/daily-summary', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const userId = uid(req);
    await requireMember(babyId, userId);
    const body = DailySummaryBody.parse(req.body ?? {});

    const [user, baby, entries] = await Promise.all([
      prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      prisma.baby.findUniqueOrThrow({ where: { id: babyId } }),
      prisma.entry.findMany({
        where: {
          babyId,
          startedAt: { gte: new Date(Date.now() - 24 * 3600_000) },
        },
        orderBy: { startedAt: 'desc' },
      }),
    ]);

    const he = (body.locale ?? user.locale) === 'he';
    let feeds = 0;
    let bottleMl = 0;
    let breastMin = 0;
    let sleepMin = 0;
    let diapersWet = 0;
    let diapersDirty = 0;

    for (const e of entries) {
      const d = (e.data ?? {}) as Record<string, any>;
      if (e.type === 'FEED') {
        feeds++;
        if (typeof d.amountMl === 'number') bottleMl += d.amountMl;
        if (typeof d.durationMin === 'number') breastMin += d.durationMin;
      } else if (e.type === 'SLEEP' && e.endedAt) {
        sleepMin += Math.max(0, Math.round((e.endedAt.getTime() - e.startedAt.getTime()) / 60_000));
      } else if (e.type === 'DIAPER') {
        if (d.kind === 'wet' || d.kind === 'both') diapersWet++;
        if (d.kind === 'dirty' || d.kind === 'both') diapersDirty++;
      }
    }

    const sleepHrs = (sleepMin / 60).toFixed(1);

    const prompt = he
      ? `כתוב סיכום יומי חם, קצר ומעודד להורים של ${baby.name} עבור 24 השעות האחרונות:\n- האכלות: ${feeds} (${bottleMl} מ"ל בקבוק, ${breastMin} דק' הנקה)\n- שינה: ${sleepHrs} שעות (${sleepMin} דקות)\n- חיתולים: ${diapersWet} רטובים, ${diapersDirty} מלוכלכים\nהוסף טיפ אחד עדין ופרקטי למחר.`
      : `Write a warm, concise daily summary for ${baby.name}'s parents covering the last 24 hours:\n- Feedings: ${feeds} (${bottleMl} ml bottle, ${breastMin} min nursing)\n- Total Sleep: ${sleepHrs} hours (${sleepMin} min)\n- Diapers: ${diapersWet} wet, ${diapersDirty} dirty\nInclude one gentle, practical tip for tomorrow.`;

    let summaryText = await callDeepSeek(
      'You are BabyDaily AI creating a daily digest for parents. Keep it under 120 words, warm and clear.',
      prompt,
    );

    if (!summaryText) {
      summaryText = he
        ? `סיכום יומי עבור ${baby.name}: ב-24 השעות האחרונות תועדו ${feeds} האכלות (${bottleMl} מ"ל בבקבוק, ${breastMin} דק׳ הנקה), סה"כ ${sleepHrs} שעות שינה, ו-${diapersWet + diapersDirty} החלפות חיתול (${diapersWet} רטובים). טיפ למחר: שמירה על שגרת ערב קבועה תורמת לשינה רגועה ורציפה יותר!`
        : `Daily Digest for ${baby.name}: Over the last 24 hours, you logged ${feeds} feedings (${bottleMl}ml bottle, ${breastMin}m nursing), ${sleepHrs} hours of sleep, and ${diapersWet + diapersDirty} diapers (${diapersWet} wet). Tip for tomorrow: A calm 15-minute wind-down before naps helps lengthen daytime sleep stretches!`;
    }

    let notificationSent = false;
    if (body.sendNotification) {
      await notifyUser(userId, {
        babyId,
        title: he ? `✨ הסיכום היומי של ${baby.name} מוכן` : `✨ ${baby.name}'s AI Daily Summary`,
        body: summaryText,
        data: { type: 'AI_DAILY_SUMMARY', babyId },
      });
      notificationSent = true;
    }

    let emailSent = false;
    if (body.sendToEmail && user.email) {
      const subject = he
        ? `✨ הסיכום היומי של ${baby.name} — BabyDaily AI`
        : `✨ ${baby.name}'s Daily AI Summary — BabyDaily`;
      const html = `<!doctype html><html lang="${he ? 'he' : 'en'}" dir="${he ? 'rtl' : 'ltr'}"><body style="margin:0;background:#FFF9F4;font-family:'Nunito','Segoe UI',Arial,sans-serif;color:#2B2A3D;padding:24px">
        <div style="max-width:520px;margin:0 auto;background:#ffffff;border-radius:24px;overflow:hidden;box-shadow:0 4px 16px rgba(0,0,0,0.06)">
          <div style="background:linear-gradient(135deg,#8C7AE6,#FF7A59);padding:28px;color:#fff;text-align:center">
            <div style="font-size:36px">✨👶</div>
            <h2 style="margin:8px 0 0;font-size:22px">${subject}</h2>
          </div>
          <div style="padding:24px;font-size:15px;line-height:1.6">
            <p style="white-space:pre-line">${summaryText}</p>
            <div style="display:flex;gap:10px;margin-top:20px;background:#FFF5F2;padding:14px;border-radius:16px;font-weight:700;font-size:13px">
              <span>🍼 ${feeds} Feeds (${bottleMl}ml)</span> &nbsp;|&nbsp;
              <span>😴 ${sleepHrs}h Sleep</span> &nbsp;|&nbsp;
              <span>🧷 ${diapersWet + diapersDirty} Diapers</span>
            </div>
          </div>
        </div>
      </body></html>`;
      const mailRes = await sendEmail(user.email, subject, html, summaryText);
      emailSent = mailRes.sent;
    }

    return {
      summary: summaryText,
      stats: { feeds, bottleMl, breastMin, sleepMin, diapersWet, diapersDirty },
      notificationSent,
      emailSent,
    };
  });

  // ---------------- Multi-Day Statistics (Premium Analytics) ----------------
  app.get('/babies/:babyId/stats', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    const { days } = StatsQuery.parse(req.query);

    const now = new Date();
    const start = new Date(now.getTime() - days * 86_400_000);

    const entries = await prisma.entry.findMany({
      where: {
        babyId,
        startedAt: { gte: start },
      },
      orderBy: { startedAt: 'asc' },
    });

    const buckets = new Map<
      string,
      {
        date: string;
        feedsCount: number;
        bottleMl: number;
        breastMinutes: number;
        sleepMinutes: number;
        napsCount: number;
        diapersWet: number;
        diapersDirty: number;
        diapersTotal: number;
      }
    >();

    for (let i = days - 1; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 86_400_000);
      const key = d.toISOString().slice(0, 10);
      buckets.set(key, {
        date: key,
        feedsCount: 0,
        bottleMl: 0,
        breastMinutes: 0,
        sleepMinutes: 0,
        napsCount: 0,
        diapersWet: 0,
        diapersDirty: 0,
        diapersTotal: 0,
      });
    }

    let longestSleepMinutes = 0;

    for (const e of entries) {
      const key = e.startedAt.toISOString().slice(0, 10);
      const b = buckets.get(key);
      if (!b) continue;
      const d = (e.data ?? {}) as Record<string, any>;

      if (e.type === 'FEED') {
        b.feedsCount++;
        if (typeof d.amountMl === 'number') b.bottleMl += d.amountMl;
        if (typeof d.durationMin === 'number') b.breastMinutes += d.durationMin;
      } else if (e.type === 'SLEEP' && e.endedAt) {
        const dur = Math.max(0, Math.round((e.endedAt.getTime() - e.startedAt.getTime()) / 60_000));
        b.sleepMinutes += dur;
        b.napsCount++;
        if (dur > longestSleepMinutes) longestSleepMinutes = dur;
      } else if (e.type === 'DIAPER') {
        b.diapersTotal++;
        if (d.kind === 'wet' || d.kind === 'both') b.diapersWet++;
        if (d.kind === 'dirty' || d.kind === 'both') b.diapersDirty++;
      }
    }

    const daily = Array.from(buckets.values()).map((b) => ({
      ...b,
      sleepHours: Number((b.sleepMinutes / 60).toFixed(1)),
    }));

    const totalFeeds = daily.reduce((s, d) => s + d.feedsCount, 0);
    const totalBottleMl = daily.reduce((s, d) => s + d.bottleMl, 0);
    const totalSleepMin = daily.reduce((s, d) => s + d.sleepMinutes, 0);
    const totalDiapers = daily.reduce((s, d) => s + d.diapersTotal, 0);

    return {
      days,
      daily,
      averages: {
        avgFeedsPerDay: Number((totalFeeds / days).toFixed(1)),
        avgBottleMlPerDay: Math.round(totalBottleMl / days),
        avgSleepHoursPerDay: Number((totalSleepMin / 60 / days).toFixed(1)),
        avgDiapersPerDay: Number((totalDiapers / days).toFixed(1)),
        longestSleepMinutes,
      },
    };
  });

  // ---------------- Subscription & Premium Upgrade ----------------
  app.post('/me/subscription', async (req) => {
    const userId = uid(req);
    const body = SubscriptionBody.parse(req.body);
    const isPremium = body.plan !== 'FREE';

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        isPremium,
        subscriptionPlan: body.plan,
        subscriptionSince: isPremium ? new Date() : null,
        ...(body.dailySummaryEmail !== undefined ? { dailySummaryEmail: body.dailySummaryEmail } : {}),
      },
    });

    return toUserDto(updated);
  });
}
