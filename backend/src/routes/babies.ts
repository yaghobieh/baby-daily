import type { FastifyInstance } from 'fastify';
import type { Entry, Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import { requireMember } from '../lib/access.js';
import { badRequest, notFound } from '../lib/errors.js';
import { publicUserSelect, uid } from '../lib/http.js';
import { t } from '../lib/i18n.js';
import { BabyBody, BabyParams, EntryBody, EntryData, EntryPatchBody, EntryQuery, IdParams, RangeQuery } from '../schemas.js';
import { notifyBabyMembers } from '../services/notify.js';
import { rescheduleAfterEntry } from '../services/scheduler.js';

const entryInclude = { createdBy: { select: { id: true, name: true } } } as const;

function validateData(type: Entry['type'], data: unknown) {
  const res = EntryData[type].safeParse(data ?? {});
  if (!res.success) throw badRequest('invalid_entry_data', res.error.issues.map((i) => i.message).join('; '));
  return res.data as Prisma.InputJsonValue;
}

export default async function babyRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // ---------------- Babies ----------------
  app.get('/babies', async (req) => {
    const ms = await prisma.babyMember.findMany({
      where: { userId: uid(req) },
      include: { baby: { include: { _count: { select: { members: true } } } } },
      orderBy: { createdAt: 'asc' },
    });
    return ms.map(({ baby, role }) => ({ ...baby, role, memberCount: baby._count.members, _count: undefined }));
  });

  app.post('/babies', async (req, reply) => {
    const b = BabyBody.parse(req.body);
    const baby = await prisma.baby.create({
      data: {
        name: b.name,
        birthDate: b.birthDate ?? null,
        gender: b.gender ?? null,
        ...(b.avatarColor ? { avatarColor: b.avatarColor } : {}),
        members: { create: { userId: uid(req), role: 'OWNER' } },
      },
    });
    return reply.code(201).send({ ...baby, role: 'OWNER', memberCount: 1 });
  });

  app.get('/babies/:babyId', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const m = await requireMember(babyId, uid(req));
    const baby = await prisma.baby.findUniqueOrThrow({
      where: { id: babyId },
      include: { _count: { select: { members: true } } },
    });
    return { ...baby, role: m.role, memberCount: baby._count.members, _count: undefined };
  });

  app.patch('/babies/:babyId', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    const m = await requireMember(babyId, uid(req), 'OWNER');
    const b = BabyBody.partial().parse(req.body);
    const baby = await prisma.baby.update({ where: { id: babyId }, data: b });
    return { ...baby, role: m.role };
  });

  app.delete('/babies/:babyId', async (req, reply) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req), 'OWNER');
    await prisma.baby.delete({ where: { id: babyId } });
    return reply.code(204).send();
  });

  // ---------------- Entries ----------------
  app.get('/babies/:babyId/entries', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    const q = EntryQuery.parse(req.query);
    return prisma.entry.findMany({
      where: {
        babyId,
        ...(q.type ? { type: q.type } : {}),
        ...(q.from || q.to ? { startedAt: { ...(q.from ? { gte: q.from } : {}), ...(q.to ? { lt: q.to } : {}) } } : {}),
      },
      include: entryInclude,
      orderBy: { startedAt: 'desc' },
      take: q.limit,
    });
  });

  app.post('/babies/:babyId/entries', async (req, reply) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req), 'CAREGIVER');
    const b = EntryBody.parse(req.body);
    if (b.endedAt && b.endedAt < b.startedAt) throw badRequest('ended_before_started');
    if (b.photoId) {
      const p = await prisma.photo.findFirst({ where: { id: b.photoId, babyId }, select: { id: true } });
      if (!p) throw badRequest('invalid_photo');
    }

    const entry = await prisma.entry.create({
      data: {
        babyId,
        createdById: uid(req),
        type: b.type,
        startedAt: b.startedAt,
        endedAt: b.endedAt ?? null,
        data: validateData(b.type, b.data),
        note: b.note ?? null,
        photoId: b.photoId ?? null,
      },
      include: { ...entryInclude, baby: { select: { name: true } } },
    });

    void (async () => {
      await rescheduleAfterEntry(babyId, entry.type);
      await notifyBabyMembers({
        babyId,
        exceptUserId: uid(req),
        entryType: entry.type,
        build: (l) => t.entryLogged(l, entry.type, entry.createdBy.name, entry.baby.name),
        data: { type: 'entry', entryId: entry.id, entryType: entry.type },
      });
    })().catch((e) => req.log.error(e));

    const { baby: _b, ...rest } = entry;
    return reply.code(201).send(rest);
  });

  app.patch('/entries/:id', async (req) => {
    const { id } = IdParams.parse(req.params);
    const existing = await prisma.entry.findUnique({ where: { id } });
    if (!existing) throw notFound('entry_not_found');
    await requireMember(existing.babyId, uid(req), 'CAREGIVER');
    const b = EntryPatchBody.parse(req.body);

    const startedAt = b.startedAt ?? existing.startedAt;
    const endedAt = b.endedAt === undefined ? existing.endedAt : b.endedAt;
    if (endedAt && endedAt < startedAt) throw badRequest('ended_before_started');

    const entry = await prisma.entry.update({
      where: { id },
      data: {
        startedAt,
        endedAt,
        ...(b.data !== undefined ? { data: validateData(existing.type, b.data) } : {}),
        ...(b.note !== undefined ? { note: b.note } : {}),
        ...(b.photoId !== undefined ? { photoId: b.photoId } : {}),
      },
      include: { ...entryInclude, baby: { select: { name: true } } },
    });

    // Sleep just ended → tell followers the baby woke up
    const wokeUp = existing.type === 'SLEEP' && !existing.endedAt && entry.endedAt;
    void (async () => {
      await rescheduleAfterEntry(entry.babyId, entry.type);
      if (wokeUp) {
        const actor = (await prisma.user.findUnique({ where: { id: uid(req) }, select: { name: true } }))?.name ?? '';
        const mins = Math.round((entry.endedAt!.getTime() - entry.startedAt.getTime()) / 60_000);
        await notifyBabyMembers({
          babyId: entry.babyId,
          exceptUserId: uid(req),
          entryType: 'SLEEP',
          build: (l) => t.sleepEnded(l, actor, entry.baby.name, mins),
          data: { type: 'entry', entryId: entry.id, entryType: 'SLEEP' },
        });
      }
    })().catch((e) => req.log.error(e));

    const { baby: _b, ...rest } = entry;
    return rest;
  });

  app.delete('/entries/:id', async (req, reply) => {
    const { id } = IdParams.parse(req.params);
    const existing = await prisma.entry.findUnique({ where: { id } });
    if (!existing) throw notFound('entry_not_found');
    await requireMember(existing.babyId, uid(req), 'CAREGIVER');
    await prisma.entry.delete({ where: { id } });
    void rescheduleAfterEntry(existing.babyId, existing.type).catch((e) => req.log.error(e));
    return reply.code(204).send();
  });

  // ---------------- Daily summary ----------------
  app.get('/babies/:babyId/summary', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    const { from, to } = RangeQuery.parse(req.query);

    const [today, lastByType, activeSleep] = await Promise.all([
      prisma.entry.findMany({
        where: {
          babyId,
          OR: [
            { startedAt: { gte: from, lt: to } },
            // sleeps that started before today but overlap it
            { type: 'SLEEP', startedAt: { lt: from }, OR: [{ endedAt: null }, { endedAt: { gt: from } }] },
          ],
        },
      }),
      Promise.all(
        (['FEED', 'SLEEP', 'DIAPER', 'GROWTH', 'MEDICINE'] as const).map((type) =>
          prisma.entry.findFirst({ where: { babyId, type }, orderBy: { startedAt: 'desc' }, include: entryInclude }),
        ),
      ),
      prisma.entry.findFirst({ where: { babyId, type: 'SLEEP', endedAt: null }, orderBy: { startedAt: 'desc' } }),
    ]);

    const now = new Date();
    let sleepMinutes = 0;
    let feeds = 0;
    let bottleMl = 0;
    let breastMinutes = 0;
    const diapers = { total: 0, wet: 0, dirty: 0 };

    for (const e of today) {
      const d = (e.data ?? {}) as Record<string, unknown>;
      if (e.type === 'SLEEP') {
        const s = Math.max(e.startedAt.getTime(), from.getTime());
        const end = Math.min((e.endedAt ?? now).getTime(), to.getTime());
        if (end > s) sleepMinutes += Math.round((end - s) / 60_000);
      } else if (e.type === 'FEED' && e.startedAt >= from) {
        feeds++;
        if (typeof d.amountMl === 'number') bottleMl += d.amountMl;
        if (d.method === 'breast' && e.endedAt) breastMinutes += Math.round((e.endedAt.getTime() - e.startedAt.getTime()) / 60_000);
      } else if (e.type === 'DIAPER') {
        diapers.total++;
        if (d.kind === 'wet' || d.kind === 'mixed') diapers.wet++;
        if (d.kind === 'dirty' || d.kind === 'mixed') diapers.dirty++;
      }
    }

    const [lastFeed, lastSleep, lastDiaper, lastGrowth, lastMedicine] = lastByType;
    return {
      feeds,
      bottleMl,
      breastMinutes,
      sleepMinutes,
      diapers,
      activeSleep,
      last: { feed: lastFeed, sleep: lastSleep, diaper: lastDiaper, growth: lastGrowth, medicine: lastMedicine },
    };
  });

  // Members list is used by several screens; keep it here as a read-only view.
  app.get('/babies/:babyId/members', async (req) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    return prisma.babyMember.findMany({
      where: { babyId },
      select: { id: true, role: true, createdAt: true, user: { select: publicUserSelect } },
      orderBy: [{ role: 'asc' }, { createdAt: 'asc' }],
    });
  });

  // ---------------- Export to CSV / PDF / Word ----------------
  app.get('/babies/:babyId/export', async (req, reply) => {
    const { babyId } = BabyParams.parse(req.params);
    await requireMember(babyId, uid(req));
    const format = ((req.query as Record<string, string>)?.format ?? 'csv').toLowerCase();

    const baby = await prisma.baby.findUniqueOrThrow({ where: { id: babyId } });
    const entries = await prisma.entry.findMany({
      where: { babyId },
      include: entryInclude,
      orderBy: { startedAt: 'desc' },
      take: 500,
    });

    const formatEntryDetails = (e: (typeof entries)[number]) => {
      const d = (e.data ?? {}) as Record<string, unknown>;
      switch (e.type) {
        case 'FEED':
          return d.method === 'bottle'
            ? `בקבוק ${d.amountMl ?? 0} מ״ל`
            : d.method === 'breast'
              ? `הנקה (${d.side === 'both' ? 'שני הצדדים' : d.side === 'left' ? 'שמאל' : 'ימין'})`
              : `מוצקים: ${d.food ?? ''}`;
        case 'SLEEP': {
          const mins = e.endedAt ? Math.round((e.endedAt.getTime() - e.startedAt.getTime()) / 60000) : null;
          return mins ? `שינה של ${mins} דקות` : 'ישן/ה כעת';
        }
        case 'DIAPER':
          return d.kind === 'wet' ? 'רטוב' : d.kind === 'dirty' ? 'מלוכלך' : d.kind === 'mixed' ? 'רטוב ומלוכלך' : 'נקי';
        case 'MEDICINE':
          return `${d.name ?? 'תרופה'} (${d.dose ?? ''})`;
        case 'GROWTH': {
          const parts = [];
          if (d.weightKg) parts.push(`משקל: ${d.weightKg} ק״ג`);
          if (d.heightCm) parts.push(`גובה: ${d.heightCm} ס״מ`);
          if (d.headCm) parts.push(`היקף ראש: ${d.headCm} ס״מ`);
          return parts.join(', ');
        }
        case 'NOTE':
          return (d.text as string) ?? '';
        default:
          return '';
      }
    };

    const typeNames: Record<string, string> = {
      FEED: 'האכלה',
      SLEEP: 'שינה',
      DIAPER: 'חיתול',
      MEDICINE: 'תרופה',
      GROWTH: 'גדילה',
      NOTE: 'הערה',
    };

    if (format === 'csv') {
      const header = 'תאריך,שעה,סוג פעילות,פרטים,הערות,נרשם על ידי';
      const rows = entries.map((e) => {
        const date = e.startedAt.toLocaleDateString('he-IL');
        const time = e.startedAt.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' });
        const type = typeNames[e.type] ?? e.type;
        const details = `"${formatEntryDetails(e).replace(/"/g, '""')}"`;
        const note = `"${(e.note ?? '').replace(/"/g, '""')}"`;
        const author = `"${e.createdBy.name.replace(/"/g, '""')}"`;
        return `${date},${time},${type},${details},${note},${author}`;
      });
      const csv = '\uFEFF' + [header, ...rows].join('\r\n');
      reply.header('Content-Type', 'text/csv; charset=utf-8');
      reply.header('Content-Disposition', `attachment; filename="${encodeURIComponent(baby.name)}_report.csv"`);
      return reply.send(csv);
    }

    if (format === 'word' || format === 'doc') {
      const rowsHtml = entries.map((e) => {
        const date = e.startedAt.toLocaleDateString('he-IL') + ' ' + e.startedAt.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' });
        return `<tr>
          <td style="padding:8px;border:1px solid #ddd;">${date}</td>
          <td style="padding:8px;border:1px solid #ddd;font-weight:bold;">${typeNames[e.type] ?? e.type}</td>
          <td style="padding:8px;border:1px solid #ddd;">${formatEntryDetails(e)}</td>
          <td style="padding:8px;border:1px solid #ddd;">${e.note ?? '-'}</td>
          <td style="padding:8px;border:1px solid #ddd;">${e.createdBy.name}</td>
        </tr>`;
      }).join('');

      const docHtml = `
      <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
      <head><meta charset='utf-8'><title>דוח שגרה יומי - ${baby.name}</title>
      <style>
        body { font-family: 'Arial', sans-serif; direction: rtl; text-align: right; margin: 40px; }
        h1 { color: #FF7A7A; }
        .meta { margin-bottom: 24px; padding: 12px; background: #FFF5F5; border-radius: 8px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #FF7A7A; color: white; padding: 10px; border: 1px solid #ddd; text-align: right; }
      </style>
      </head>
      <body>
        <h1>👶 דוח שגרת יום - בייבי דיילי</h1>
        <div class="meta">
          <strong>שם התינוק/ת:</strong> ${baby.name} | <strong>תאריך הפקה:</strong> ${new Date().toLocaleDateString('he-IL')} | <strong>סה״כ רשומות:</strong> ${entries.length}
        </div>
        <table>
          <thead>
            <tr><th>תאריך ושעה</th><th>סוג פעילות</th><th>פרטים</th><th>הערות</th><th>נרשם על ידי</th></tr>
          </thead>
          <tbody>${rowsHtml}</tbody>
        </table>
      </body></html>`;

      reply.header('Content-Type', 'application/msword; charset=utf-8');
      reply.header('Content-Disposition', `attachment; filename="${encodeURIComponent(baby.name)}_report.doc"`);
      return reply.send(docHtml);
    }

    // Default: Printable HTML / PDF
    const rowsHtml = entries.map((e) => {
      const date = e.startedAt.toLocaleDateString('he-IL') + ' ' + e.startedAt.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' });
      return `<tr>
        <td>${date}</td>
        <td><strong>${typeNames[e.type] ?? e.type}</strong></td>
        <td>${formatEntryDetails(e)}</td>
        <td>${e.note ?? '-'}</td>
        <td>${e.createdBy.name}</td>
      </tr>`;
    }).join('');

    const printableHtml = `
    <!DOCTYPE html>
    <html lang="he" dir="rtl">
    <head>
      <meta charset="utf-8">
      <title>דוח מעקב רפואי ושגרה - ${baby.name}</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; direction: rtl; padding: 30px; color: #2D3748; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #FF8A7A; padding-bottom: 16px; margin-bottom: 24px; }
        .logo { font-size: 24px; font-weight: bold; color: #FF8A7A; }
        .card { background: #FFF5F5; border-radius: 12px; padding: 16px; margin-bottom: 24px; }
        table { width: 100%; border-collapse: collapse; margin-top: 16px; font-size: 14px; }
        th { background: #F7FAFC; padding: 12px 8px; border-bottom: 2px solid #E2E8F0; text-align: right; }
        td { padding: 10px 8px; border-bottom: 1px solid #EDF2F7; text-align: right; }
        .print-btn { background: #FF8A7A; color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: bold; }
        @media print { .no-print { display: none !important; } body { padding: 0; } }
      </style>
    </head>
    <body>
      <div class="header">
        <div>
          <div class="logo">👶 בייבי דיילי - דוח שגרה ורפואי</div>
          <div>תיעוד יומי ומעקב התפתחות עבור ${baby.name}</div>
        </div>
        <div class="no-print">
          <button class="print-btn" onclick="window.print()">🖨️ הדפסה / שמירה כ-PDF</button>
        </div>
      </div>
      <div class="card">
        <strong>תינוק/ת:</strong> ${baby.name} &nbsp;|&nbsp; 
        <strong>תאריך הפקה:</strong> ${new Date().toLocaleDateString('he-IL')} ${new Date().toLocaleTimeString('he-IL')} &nbsp;|&nbsp; 
        <strong>סה״כ רשומות בדוח:</strong> ${entries.length}
      </div>
      <table>
        <thead>
          <tr>
            <th>זמן</th>
            <th>סוג</th>
            <th>פרטים מלאים</th>
            <th>הערות</th>
            <th>מטפל/ת</th>
          </tr>
        </thead>
        <tbody>${rowsHtml}</tbody>
      </table>
    </body>
    </html>`;

    reply.header('Content-Type', 'text/html; charset=utf-8');
    return reply.send(printableHtml);
  });
}
