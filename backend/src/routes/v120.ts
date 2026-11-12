import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db.js';
import { requireMember } from '../lib/access.js';
import { notFound } from '../lib/errors.js';
import { uid } from '../lib/http.js';
import { BabyParams } from '../schemas.js';

const ConsumeStashParams = z.object({
  babyId: z.string().min(1),
  entryId: z.string().min(1),
});

const ParseEntryBody = z.object({
  text: z.string().trim().min(2).max(1000),
});

const TOP_9_ALLERGENS = [
  { key: 'egg', name: 'Egg', icon: '🥚' },
  { key: 'dairy', name: 'Dairy / Cow Milk', icon: '🧀' },
  { key: 'peanut', name: 'Peanut', icon: '🥜' },
  { key: 'tree_nut', name: 'Tree Nuts', icon: '🌰' },
  { key: 'soy', name: 'Soy', icon: '🫘' },
  { key: 'wheat', name: 'Wheat / Gluten', icon: '🌾' },
  { key: 'fish', name: 'Fish', icon: '🐟' },
  { key: 'shellfish', name: 'Shellfish', icon: '🦐' },
  { key: 'sesame', name: 'Sesame / Tahini', icon: '🥯' },
] as const;

const CDC_MILESTONES = [
  { key: 'smile_2m', ageMonths: 2, category: 'social', title: 'Smiles when you talk to or smile at them' },
  { key: 'head_up_2m', ageMonths: 2, category: 'motor', title: 'Holds head up during tummy time' },
  { key: 'coos_2m', ageMonths: 2, category: 'language', title: 'Makes cooing and gurgling sounds' },
  { key: 'chuckles_4m', ageMonths: 4, category: 'social', title: 'Chuckles and laughs out loud' },
  { key: 'roll_tummy_back_4m', ageMonths: 4, category: 'motor', title: 'Rolls from tummy to back & pushes up on elbows' },
  { key: 'grab_toy_4m', ageMonths: 4, category: 'cognitive', title: 'Reaches for and grasps toys with one hand' },
  { key: 'sit_support_6m', ageMonths: 6, category: 'motor', title: 'Sits with support and rolls both ways' },
  { key: 'babble_6m', ageMonths: 6, category: 'language', title: 'Takes turns making sounds and blows raspberries' },
  { key: 'stranger_9m', ageMonths: 9, category: 'social', title: 'Shows several facial expressions & responds to own name' },
  { key: 'sit_alone_9m', ageMonths: 9, category: 'motor', title: 'Sits without support and pulls to stand' },
  { key: 'mama_dada_12m', ageMonths: 12, category: 'language', title: 'Waves "bye-bye" and says "mama" or "dada"' },
  { key: 'cruise_12m', ageMonths: 12, category: 'motor', title: 'Cruises along furniture or takes first steps' },
] as const;

const WHO_WEIGHT_BOYS_KG = [
  { month: 0, p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.3 },
  { month: 1, p3: 3.4, p15: 3.9, p50: 4.5, p85: 5.1, p97: 5.7 },
  { month: 2, p3: 4.4, p15: 4.9, p50: 5.6, p85: 6.3, p97: 7.0 },
  { month: 3, p3: 5.1, p15: 5.7, p50: 6.4, p85: 7.2, p97: 7.9 },
  { month: 4, p3: 5.6, p15: 6.2, p50: 7.0, p85: 7.8, p97: 8.6 },
  { month: 6, p3: 6.4, p15: 7.1, p50: 7.9, p85: 8.8, p97: 9.7 },
  { month: 9, p3: 7.2, p15: 8.0, p50: 8.9, p85: 9.9, p97: 10.9 },
  { month: 12, p3: 7.8, p15: 8.6, p50: 9.6, p85: 10.8, p97: 11.8 },
];

const VACCINE_SCHEDULE = [
  { code: 'HepB_1', ageLabel: 'Birth', name: 'Hepatitis B (1st dose)' },
  { code: 'DTaP_1', ageLabel: '2 Months', name: 'DTaP + IPV + Hib + PCV13 (1st dose)' },
  { code: 'RV_1', ageLabel: '2 Months', name: 'Rotavirus Oral (1st dose)' },
  { code: 'DTaP_2', ageLabel: '4 Months', name: 'DTaP + IPV + Hib + PCV13 (2nd dose)' },
  { code: 'RV_2', ageLabel: '4 Months', name: 'Rotavirus Oral (2nd dose)' },
  { code: 'DTaP_3', ageLabel: '6 Months', name: 'DTaP + PCV13 + HepB (3rd dose)' },
  { code: 'MMR_1', ageLabel: '12 Months', name: 'MMR + Varicella (1st dose)' },
];

function estimatePercentile(val: number, row: { p3: number; p15: number; p50: number; p85: number; p97: number }): number {
  if (val <= row.p3) return 3;
  if (val <= row.p15) return Math.round(3 + ((val - row.p3) / (row.p15 - row.p3)) * 12);
  if (val <= row.p50) return Math.round(15 + ((val - row.p15) / (row.p50 - row.p15)) * 35);
  if (val <= row.p85) return Math.round(50 + ((val - row.p50) / (row.p85 - row.p50)) * 35);
  if (val <= row.p97) return Math.round(85 + ((val - row.p85) / (row.p97 - row.p85)) * 12);
  return 98;
}

export default async function v120Routes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // ---------------- AL-116: Pumping & Breast Milk Stash Manager ----------------
  app.get('/babies/:babyId/milk-stash', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));

    const feedEntries = await prisma.entry.findMany({
      where: { babyId, type: 'FEED' },
      orderBy: { startedAt: 'asc' },
      take: 250,
    });

    const now = Date.now();
    const bags: Array<{
      id: string;
      pumpedAt: string;
      expiresAt: string;
      isExpiringSoon: boolean;
      isExpired: boolean;
      storageLocation: 'fridge' | 'freezer';
      volumeMl: number;
      leftMl: number;
      rightMl: number;
      note: string | null;
    }> = [];

    let totalFridgeMl = 0;
    let totalFreezerMl = 0;
    let expiringSoonCount = 0;

    for (const e of feedEntries) {
      const d = (e.data ?? {}) as Record<string, any>;
      const isPump = d.method === 'pump' || d.kind === 'pump';
      if (!isPump || d.consumedAt) continue;
      const loc = d.storageLocation === 'freezer' ? 'freezer' : d.storageLocation === 'fridge' ? 'fridge' : null;
      if (!loc) continue;

      const leftMl = typeof d.leftMl === 'number' ? d.leftMl : 0;
      const rightMl = typeof d.rightMl === 'number' ? d.rightMl : 0;
      const volumeMl = typeof d.amountMl === 'number' ? d.amountMl : leftMl + rightMl;
      if (volumeMl <= 0) continue;

      const maxAgeMs = loc === 'fridge' ? 4 * 86_400_000 : 180 * 86_400_000;
      const expiresAtMs = e.startedAt.getTime() + maxAgeMs;
      const hoursLeft = (expiresAtMs - now) / 3_600_000;
      const isExpired = hoursLeft <= 0;
      const isExpiringSoon = !isExpired && hoursLeft <= 24;

      if (loc === 'fridge') totalFridgeMl += volumeMl;
      else totalFreezerMl += volumeMl;
      if (isExpiringSoon) expiringSoonCount++;

      bags.push({
        id: e.id,
        pumpedAt: e.startedAt.toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        isExpiringSoon,
        isExpired,
        storageLocation: loc,
        volumeMl,
        leftMl,
        rightMl,
        note: e.note ?? (typeof d.note === 'string' ? d.note : null),
      });
    }

    return {
      totalFridgeMl,
      totalFreezerMl,
      totalBags: bags.length,
      expiringSoonCount,
      bags,
    };
  });

  app.post('/babies/:babyId/milk-stash/:entryId/consume', async (req) => {
    const { babyId, entryId } = ConsumeStashParams.parse(req.params);
    const userId = uid(req);
    await requireMember(babyId, userId, 'CAREGIVER');

    const bag = await prisma.entry.findFirst({ where: { id: entryId, babyId, type: 'FEED' } });
    if (!bag) throw notFound('milk_bag_not_found');

    const d = (bag.data ?? {}) as Record<string, any>;
    const volumeMl = typeof d.amountMl === 'number' ? d.amountMl : (d.leftMl ?? 0) + (d.rightMl ?? 0);
    const consumedAt = new Date().toISOString();

    const [updatedBag, bottleFeed] = await prisma.$transaction([
      prisma.entry.update({
        where: { id: bag.id },
        data: { data: { ...d, consumedAt } },
      }),
      prisma.entry.create({
        data: {
          babyId,
          createdById: userId,
          type: 'FEED',
          startedAt: new Date(),
          endedAt: new Date(),
          data: {
            method: 'bottle',
            kind: 'bottle',
            amountMl: volumeMl,
            milkType: 'expressed_breast_milk',
            consumedFromStashId: bag.id,
          },
          note: `Fed ${volumeMl}ml from stored breast milk stash`,
        },
      }),
    ]);

    return { consumedBagId: updatedBag.id, bottleEntry: bottleFeed };
  });

  // ---------------- AL-117: 100 First Foods & Top 9 Allergen Tracker ----------------
  app.get('/babies/:babyId/solids-summary', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));

    const feeds = await prisma.entry.findMany({
      where: { babyId, type: 'FEED' },
      orderBy: { startedAt: 'desc' },
      take: 400,
    });

    const foodMap = new Map<
      string,
      {
        food: string;
        category: string;
        exposureCount: number;
        preference: string;
        reaction: string;
        texture: string;
        lastTriedAt: string;
      }
    >();

    const allergenStats = new Map<string, { exposures: number; reaction: string }>();

    for (const e of feeds) {
      const d = (e.data ?? {}) as Record<string, any>;
      const isSolids = d.method === 'solids' || d.kind === 'solids' || typeof d.food === 'string';
      if (!isSolids || !d.food) continue;

      const foodName = String(d.food).trim();
      const key = foodName.toLowerCase();
      const existing = foodMap.get(key);
      const reaction = typeof d.reaction === 'string' ? d.reaction : 'none';
      const preference = typeof d.preference === 'string' ? d.preference : 'loved';
      const texture = typeof d.texture === 'string' ? d.texture : 'puree';
      const category = typeof d.foodCategory === 'string' ? d.foodCategory : 'fruit';

      if (existing) {
        existing.exposureCount++;
        if (reaction !== 'none') existing.reaction = reaction;
      } else {
        foodMap.set(key, {
          food: foodName,
          category,
          exposureCount: 1,
          preference,
          reaction,
          texture,
          lastTriedAt: e.startedAt.toISOString(),
        });
      }

      const allergenKey = typeof d.allergenName === 'string' ? d.allergenName.toLowerCase() : key;
      for (const alg of TOP_9_ALLERGENS) {
        if (allergenKey.includes(alg.key) || key.includes(alg.name.toLowerCase().split(' ')[0])) {
          const cur = allergenStats.get(alg.key) ?? { exposures: 0, reaction: 'none' };
          cur.exposures++;
          if (reaction !== 'none') cur.reaction = reaction;
          allergenStats.set(alg.key, cur);
        }
      }
    }

    const foodsTried = Array.from(foodMap.values());
    const topAllergens = TOP_9_ALLERGENS.map((a) => {
      const st = allergenStats.get(a.key) ?? { exposures: 0, reaction: 'none' };
      return {
        ...a,
        exposures: st.exposures,
        targetExposures: 3,
        cleared: st.exposures >= 3 && st.reaction === 'none',
        reaction: st.reaction,
      };
    });

    return {
      uniqueFoodsCount: foodsTried.length,
      goalCount: 100,
      foodsTried,
      topAllergens,
    };
  });

  // ---------------- AL-118: Tummy Time Ring, Activities & CDC/WHO Milestones ----------------
  app.get('/babies/:babyId/milestones', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));

    const [baby, notes] = await Promise.all([
      prisma.baby.findUniqueOrThrow({ where: { id: babyId } }),
      prisma.entry.findMany({
        where: { babyId, type: 'NOTE' },
        orderBy: { startedAt: 'desc' },
        take: 300,
      }),
    ]);

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    let tummyTimeTodayMinutes = 0;
    const recentActivities: Array<{
      id: string;
      activityKind: string;
      durationMinutes: number;
      startedAt: string;
    }> = [];
    const achievedMap = new Map<string, string>();

    for (const n of notes) {
      const d = (n.data ?? {}) as Record<string, any>;
      if (d.subType === 'activity' || d.activityKind) {
        const dur = typeof d.durationMinutes === 'number' ? d.durationMinutes : 10;
        if (d.activityKind === 'tummy_time' && n.startedAt >= todayStart) {
          tummyTimeTodayMinutes += dur;
        }
        if (recentActivities.length < 10) {
          recentActivities.push({
            id: n.id,
            activityKind: String(d.activityKind || 'tummy_time'),
            durationMinutes: dur,
            startedAt: n.startedAt.toISOString(),
          });
        }
      }
      if (d.subType === 'milestone' && typeof d.milestoneKey === 'string') {
        achievedMap.set(d.milestoneKey, n.startedAt.toISOString());
      }
    }

    const ageWeeks = baby.birthDate
      ? Math.max(1, Math.floor((Date.now() - baby.birthDate.getTime()) / (7 * 86_400_000)))
      : 16;

    const currentLeap =
      ageWeeks <= 6
        ? { leapNumber: 1, title: 'Leap 1: Changing Sensations (Week 5)', tip: 'Baby becomes more alert to sights and sounds; extra cuddling helps.' }
        : ageWeeks <= 10
          ? { leapNumber: 2, title: 'Leap 2: Patterns & Hands (Week 8)', tip: 'Baby discovers hands and vocalizes more; great time for high-contrast cards.' }
          : ageWeeks <= 14
            ? { leapNumber: 3, title: 'Leap 3: Smooth Transitions (Week 12)', tip: 'Head control improves; practice daily tummy time in short cheerful bursts.' }
            : ageWeeks <= 21
              ? { leapNumber: 4, title: 'Leap 4: Events & 4-Month Sleep Maturation (Week 19)', tip: 'Sleep cycles mature; stick closely to 90–120m sweet-spot wake windows.' }
              : { leapNumber: 5, title: 'Leap 5: Relationships & Distance (Week 26)', tip: 'Object permanence develops; play peek-a-boo to build reassurance.' };

    const milestones = CDC_MILESTONES.map((m) => ({
      ...m,
      achieved: achievedMap.has(m.key),
      achievedAt: achievedMap.get(m.key) ?? null,
    }));

    return {
      ageWeeks,
      tummyTimeTodayMinutes,
      tummyTimeGoalMinutes: 30,
      currentLeap,
      recentActivities,
      milestones,
    };
  });

  // ---------------- AL-119: WHO Growth Percentile Curves & Vaccine Checklist ----------------
  app.get('/babies/:babyId/growth-percentiles', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));

    const [baby, growthEntries, medEntries] = await Promise.all([
      prisma.baby.findUniqueOrThrow({ where: { id: babyId } }),
      prisma.entry.findMany({
        where: { babyId, type: 'GROWTH' },
        orderBy: { startedAt: 'asc' },
      }),
      prisma.entry.findMany({
        where: { babyId, type: 'MEDICINE' },
        orderBy: { startedAt: 'desc' },
      }),
    ]);

    const birthMs = baby.birthDate?.getTime() ?? Date.now() - 120 * 86_400_000;

    const measurements = growthEntries.map((g) => {
      const d = (g.data ?? {}) as Record<string, any>;
      const ageMonths = Math.max(0, Math.round((g.startedAt.getTime() - birthMs) / (30.44 * 86_400_000)));
      const refRow =
        WHO_WEIGHT_BOYS_KG.reduce((prev, curr) =>
          Math.abs(curr.month - ageMonths) < Math.abs(prev.month - ageMonths) ? curr : prev
        ) ?? WHO_WEIGHT_BOYS_KG[3];

      const weightKg = typeof d.weightKg === 'number' ? d.weightKg : null;
      const heightCm = typeof d.heightCm === 'number' ? d.heightCm : null;
      const headCm = typeof d.headCm === 'number' ? d.headCm : null;

      return {
        id: g.id,
        date: g.startedAt.toISOString(),
        ageMonths,
        weightKg,
        heightCm,
        headCm,
        weightPercentile: weightKg != null ? estimatePercentile(weightKg, refRow) : null,
      };
    });

    const completedVaccines = new Map<string, string>();
    for (const m of medEntries) {
      const d = (m.data ?? {}) as Record<string, any>;
      if (d.isVaccine) {
        const key = String(d.vaccineCode || d.name || '').toLowerCase();
        completedVaccines.set(key, m.startedAt.toISOString());
      }
    }

    const vaccines = VACCINE_SCHEDULE.map((v) => {
      const doneAt =
        completedVaccines.get(v.code.toLowerCase()) ??
        Array.from(completedVaccines.entries()).find(([k]) =>
          k.includes(v.code.split('_')[0].toLowerCase())
        )?.[1] ??
        null;
      return {
        ...v,
        completed: Boolean(doneAt),
        completedAt: doneAt,
      };
    });

    return {
      whoWeightCurve: WHO_WEIGHT_BOYS_KG,
      measurements,
      vaccines,
    };
  });

  // ---------------- AL-120: Hands-Free AI Voice & Natural Language Logger ----------------
  app.post('/babies/:babyId/ai/parse-entry', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const userId = uid(req);
    await requireMember(babyId, userId, 'CAREGIVER');
    const { text } = ParseEntryBody.parse(req.body);

    const lower = text.toLowerCase();
    const now = Date.now();

    // Detect relative time like "20 minutes ago" or "1 hour ago"
    let offsetMs = 0;
    const minAgoMatch = lower.match(/(\d+)\s*(?:min|mins|minute|minutes)\s*ago/);
    const hrAgoMatch = lower.match(/(\d+)\s*(?:hr|hrs|hour|hours)\s*ago/);
    if (minAgoMatch) offsetMs = Number(minAgoMatch[1]) * 60_000;
    else if (hrAgoMatch) offsetMs = Number(hrAgoMatch[1]) * 3_600_000;

    const eventTime = new Date(now - offsetMs);
    const toCreate: Array<{
      type: 'FEED' | 'SLEEP' | 'DIAPER' | 'GROWTH' | 'MEDICINE' | 'NOTE';
      startedAt: Date;
      endedAt: Date | null;
      data: Record<string, any>;
      note: string;
    }> = [];

    // 1. Check for Pumping
    if (lower.includes('pump') || lower.includes('pumped')) {
      const mlMatches = [...lower.matchAll(/(\d+)\s*ml/g)].map((m) => Number(m[1]));
      const totalMl = mlMatches.length > 0 ? mlMatches.reduce((a, b) => a + b, 0) : 120;
      const loc = lower.includes('freezer') ? 'freezer' : 'fridge';
      toCreate.push({
        type: 'FEED',
        startedAt: eventTime,
        endedAt: eventTime,
        data: {
          method: 'pump',
          kind: 'pump',
          amountMl: totalMl,
          leftMl: Math.round(totalMl / 2),
          rightMl: totalMl - Math.round(totalMl / 2),
          storageLocation: loc,
        },
        note: `AI Voice Log: Pumped ${totalMl}ml (${loc})`,
      });
    } else if (
      lower.includes('ml') ||
      lower.includes('bottle') ||
      lower.includes('formula') ||
      lower.includes('drank') ||
      lower.includes('fed') ||
      lower.includes('nursed') ||
      lower.includes('breast')
    ) {
      const mlMatch = lower.match(/(\d+)\s*ml/);
      if (lower.includes('nurse') || lower.includes('breast')) {
        const durMatch = lower.match(/(\d+)\s*(?:min|m)/);
        const dur = durMatch ? Number(durMatch[1]) : 15;
        toCreate.push({
          type: 'FEED',
          startedAt: eventTime,
          endedAt: eventTime,
          data: { method: 'breast', kind: 'breast', side: 'both', durationMin: dur, durationMinutes: dur },
          note: `AI Voice Log: Nursed ${dur}m`,
        });
      } else {
        const ml = mlMatch ? Number(mlMatch[1]) : 140;
        toCreate.push({
          type: 'FEED',
          startedAt: eventTime,
          endedAt: eventTime,
          data: { method: 'bottle', kind: 'bottle', amountMl: ml, milkType: lower.includes('breast') ? 'breast_milk' : 'formula' },
          note: `AI Voice Log: Bottle ${ml}ml`,
        });
      }
    }

    // 2. Check for Diaper
    if (lower.includes('diaper') || lower.includes('wet') || lower.includes('dirty') || lower.includes('poop') || lower.includes('pee')) {
      const kind =
        (lower.includes('wet') || lower.includes('pee')) && (lower.includes('dirty') || lower.includes('poop'))
          ? 'both'
          : lower.includes('dirty') || lower.includes('poop')
            ? 'dirty'
            : 'wet';
      toCreate.push({
        type: 'DIAPER',
        startedAt: eventTime,
        endedAt: eventTime,
        data: { kind },
        note: `AI Voice Log: ${kind} diaper`,
      });
    }

    // 3. Check for Tummy Time / Activity
    if (lower.includes('tummy') || lower.includes('bath') || lower.includes('walk')) {
      const durMatch = lower.match(/(\d+)\s*(?:min|m)/);
      const dur = durMatch ? Number(durMatch[1]) : 15;
      const activityKind = lower.includes('bath') ? 'bath' : lower.includes('walk') ? 'walk' : 'tummy_time';
      toCreate.push({
        type: 'NOTE',
        startedAt: eventTime,
        endedAt: eventTime,
        data: { subType: 'activity', activityKind, durationMinutes: dur, text: `${activityKind.replace('_', ' ')} (${dur}m)` },
        note: `AI Voice Log: ${activityKind.replace('_', ' ')} for ${dur}m`,
      });
    }

    // Fallback: log as smart note if no specific pattern matched
    if (toCreate.length === 0) {
      toCreate.push({
        type: 'NOTE',
        startedAt: eventTime,
        endedAt: eventTime,
        data: { text },
        note: text,
      });
    }

    const createdEntries = [];
    for (const item of toCreate) {
      const created = await prisma.entry.create({
        data: {
          babyId,
          createdById: userId,
          type: item.type,
          startedAt: item.startedAt,
          endedAt: item.endedAt,
          data: item.data,
          note: item.note,
        },
      });
      createdEntries.push(created);
    }

    return {
      parsedCount: createdEntries.length,
      summary: createdEntries.map((c) => c.note || c.type).join(' + '),
      createdEntries,
    };
  });

  // ---------------- AL-122: Caregiver Shift Handoff Summary ----------------
  app.get('/babies/:babyId/handoff', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));

    const [baby, entries] = await Promise.all([
      prisma.baby.findUniqueOrThrow({ where: { id: babyId } }),
      prisma.entry.findMany({
        where: { babyId, startedAt: { gte: new Date(Date.now() - 24 * 3_600_000) } },
        orderBy: { startedAt: 'desc' },
        take: 100,
      }),
    ]);

    const lastFeed = entries.find((e) => e.type === 'FEED') ?? null;
    const activeSleep = entries.find((e) => e.type === 'SLEEP' && e.endedAt === null) ?? null;
    const lastCompletedSleep = entries.find((e) => e.type === 'SLEEP' && e.endedAt !== null) ?? null;
    const lastDiaper = entries.find((e) => e.type === 'DIAPER') ?? null;
    const recentMeds = entries.filter((e) => e.type === 'MEDICINE').slice(0, 3);
    const recentNotes = entries.filter((e) => e.type === 'NOTE').slice(0, 3);

    const feedDesc = lastFeed
      ? `${((lastFeed.data as any)?.amountMl ? `${(lastFeed.data as any).amountMl}ml ` : '') + ((lastFeed.data as any)?.method || (lastFeed.data as any)?.kind || 'Feed')} at ${lastFeed.startedAt.toISOString()}`
      : 'No feeds logged in last 24h';

    const sleepDesc = activeSleep
      ? `Currently sleeping since ${activeSleep.startedAt.toISOString()}`
      : lastCompletedSleep?.endedAt
        ? `Woke up ${Math.round((Date.now() - lastCompletedSleep.endedAt.getTime()) / 60_000)}m ago`
        : 'No sleep logged recently';

    const diaperDesc = lastDiaper
      ? `${(lastDiaper.data as any)?.kind || 'wet'} diaper ${Math.round((Date.now() - lastDiaper.startedAt.getTime()) / 60_000)}m ago`
      : 'No diaper logged recently';

    const shareText = [
      `👶 ${baby.name} — Caregiver Shift Handoff`,
      `🍼 Last Feed: ${feedDesc}`,
      `😴 Sleep Status: ${sleepDesc}`,
      `🧷 Last Diaper: ${diaperDesc}`,
      recentMeds.length > 0 ? `💊 Meds (24h): ${recentMeds.map((m) => (m.data as any)?.name || 'Medicine').join(', ')}` : null,
      recentNotes.length > 0 ? `📌 Notes: ${recentNotes.map((n) => (n.data as any)?.text || n.note || '').filter(Boolean).join(' | ')}` : null,
    ]
      .filter(Boolean)
      .join('\n');

    return {
      babyName: baby.name,
      generatedAt: new Date().toISOString(),
      lastFeed,
      activeSleep,
      lastCompletedSleep,
      lastDiaper,
      recentMeds,
      recentNotes,
      shareText,
    };
  });
}
