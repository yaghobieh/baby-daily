import { z } from 'zod';
import { formatName } from './lib/contact.js';

export const IdParams = z.object({ id: z.string().min(1) });
export const BabyParams = z.object({ babyId: z.string().min(1) });

export const RoleEnum = z.enum(['OWNER', 'CAREGIVER', 'VIEWER']);
export const EntryTypeEnum = z.enum(['FEED', 'SLEEP', 'DIAPER', 'GROWTH', 'MEDICINE', 'NOTE']);

// ---------- Auth ----------
export const RegisterBody = z.object({
  name: z.string().trim().min(1).max(80).transform(formatName),
  email: z.email().max(200),
  password: z.string().min(6).max(200),
  phone: z.string().trim().max(30).optional().nullable(),
  locale: z.enum(['en', 'he']).optional(),
  utcOffset: z.number().int().min(-840).max(840).optional(),
});

export const LoginBody = z.object({
  /** Email or phone number */
  identifier: z.string().trim().min(3).max(200),
  password: z.string().min(1).max(200),
  utcOffset: z.number().int().min(-840).max(840).optional(),
});

export const UpdateMeBody = z.object({
  name: z.string().trim().min(1).max(80).transform(formatName).optional(),
  phone: z.string().trim().max(30).nullable().optional(),
  locale: z.enum(['en', 'he']).optional(),
  utcOffset: z.number().int().min(-840).max(840).optional(),
});

// ---------- Babies ----------
export const BabyBody = z.object({
  name: z.string().trim().min(1).max(60).transform(formatName),
  birthDate: z.coerce.date().nullable().optional(),
  gender: z.enum(['girl', 'boy']).nullable().optional(),
  avatarColor: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/)
    .optional(),
});

export const TestNotifyBody = z.object({
  phone: z.string().trim().optional(),
  title: z.string().optional(),
  body: z.string().optional(),
  channel: z.enum(['push', 'sms', 'whatsapp', 'telegram', 'all']).default('all'),
});

// ---------- Entries ----------
export const EntryData = {
  FEED: z.object({
    method: z.enum(['breast', 'bottle', 'solids']),
    side: z.enum(['left', 'right', 'both']).optional(),
    amountMl: z.number().min(0).max(1000).optional(),
    food: z.string().max(200).optional(),
  }),
  SLEEP: z.object({}).passthrough(),
  DIAPER: z.object({ kind: z.enum(['wet', 'dirty', 'mixed', 'dry']) }),
  GROWTH: z
    .object({
      weightKg: z.number().min(0).max(50).optional(),
      heightCm: z.number().min(0).max(200).optional(),
      headCm: z.number().min(0).max(100).optional(),
    })
    .refine((d) => d.weightKg != null || d.heightCm != null || d.headCm != null, 'At least one measurement'),
  MEDICINE: z.object({
    name: z.string().trim().min(1).max(100),
    dose: z.string().max(60).optional(),
    isVaccine: z.boolean().optional(),
  }),
  NOTE: z.object({ mood: z.enum(['happy', 'calm', 'fussy', 'crying', 'sick']).optional() }),
} as const;

export const EntryBody = z.object({
  type: EntryTypeEnum,
  startedAt: z.coerce.date(),
  endedAt: z.coerce.date().nullable().optional(),
  data: z.record(z.string(), z.unknown()).optional(),
  note: z.string().max(2000).nullable().optional(),
  photoId: z.string().nullable().optional(),
  taggedUserId: z.string().nullable().optional(),
  taggedUserName: z.string().nullable().optional(),
});

export const EntryPatchBody = EntryBody.omit({ type: true }).partial();

export const EntryQuery = z.object({
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  type: EntryTypeEnum.optional(),
  limit: z.coerce.number().int().min(1).max(500).default(200),
});

export const RangeQuery = z.object({ from: z.coerce.date(), to: z.coerce.date() });

// ---------- Sharing ----------
export const InviteBody = z
  .object({
    email: z.email().max(200).optional().nullable(),
    phone: z.string().trim().max(30).optional().nullable(),
    role: RoleEnum.default('CAREGIVER'),
  })
  .refine((b) => !!b.email || !!b.phone, { message: 'email or phone required' });

export const MemberParams = z.object({ babyId: z.string(), memberId: z.string() });
export const MemberPatchBody = z.object({ role: RoleEnum });

export const SettingsBody = z.object({
  notifyEnabled: z.boolean(),
  notifyTypes: z.array(EntryTypeEnum),
  quietStart: z.number().int().min(0).max(1439).nullable(),
  quietEnd: z.number().int().min(0).max(1439).nullable(),
});

// ---------- Reminders ----------
export const ReminderBody = z
  .object({
    kind: z.enum(['AFTER_LAST', 'DAILY_AT']),
    title: z.string().trim().min(1).max(120),
    entryType: EntryTypeEnum.nullable().optional(),
    intervalMinutes: z.number().int().min(5).max(7 * 24 * 60).nullable().optional(),
    timeOfDay: z.number().int().min(0).max(1439).nullable().optional(),
    utcOffset: z.number().int().min(-840).max(840).default(0),
    enabled: z.boolean().default(true),
    taggedUserId: z.string().nullable().optional(),
    taggedUserName: z.string().nullable().optional(),
  })
  .refine((r) => (r.kind === 'AFTER_LAST' ? !!r.entryType && !!r.intervalMinutes : r.timeOfDay != null), {
    message: 'AFTER_LAST needs entryType+intervalMinutes; DAILY_AT needs timeOfDay',
  });

// ---------- Devices / photos ----------
export const DeviceBody = z.object({
  token: z.string().min(10).max(4096),
  platform: z.enum(['android', 'ios', 'web']),
});

export const PhotoBody = z.object({
  mime: z.enum(['image/jpeg', 'image/png', 'image/webp']),
  data: z.string().min(10), // base64
});
