import { env } from '../env.js';

export interface MailResult {
  sent: boolean;
  provider: 'resend' | 'log';
  error?: string;
}

/** Sends a transactional email through Resend. Without RESEND_API_KEY the message is only logged. */
export async function sendEmail(to: string, subject: string, html: string, text: string): Promise<MailResult> {
  if (!env.RESEND_API_KEY) {
    console.log(`[EMAIL not sent - RESEND_API_KEY missing] to=${to} subject="${subject}"`);
    return { sent: false, provider: 'log', error: 'RESEND_API_KEY not configured' };
  }
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: env.EMAIL_FROM, to: [to], subject, html, text }),
    });
    if (!res.ok) {
      const err = await res.text();
      console.error(`[EMAIL failed] ${res.status} ${err}`);
      return { sent: false, provider: 'resend', error: err };
    }
    return { sent: true, provider: 'resend' };
  } catch (e) {
    return { sent: false, provider: 'resend', error: (e as Error).message };
  }
}

export interface InviteMailInput {
  to: string;
  inviterName: string;
  babyName: string;
  role: 'CAREGIVER' | 'VIEWER';
  locale: string;
  /** True when the invitee already has an account (they just need to open the app). */
  hasAccount: boolean;
}

const ESC: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' };
const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ESC[c]!);

/** Branded invitation email (matches the app's coral palette). */
export function renderInviteEmail(i: InviteMailInput) {
  const he = i.locale === 'he';
  const link = i.hasAccount ? env.APP_URL : `${env.APP_URL}/?invite=1&email=${encodeURIComponent(i.to)}`;
  const roleText = he
    ? i.role === 'CAREGIVER' ? 'מטפל/ת (יכול/ה לתעד)' : 'צופה (קריאה בלבד)'
    : i.role === 'CAREGIVER' ? 'Caregiver (can log activity)' : 'Viewer (read-only)';

  const t = he
    ? {
        subject: `${i.inviterName} הזמין/ה אותך לעקוב אחרי ${i.babyName} 🍼`,
        hi: 'היי!',
        lead: `<b>${esc(i.inviterName)}</b> הזמין/ה אותך להצטרף ללוח של <b>${esc(i.babyName)}</b> ב-BabyDaily.`,
        role: 'התפקיד שלך',
        what: 'מה תקבל/י',
        bullets: ['האכלות, שינה וחיתולים בזמן אמת', 'התראות כשמשהו חדש מתועד', 'שיתוף קל בין כל המשפחה'],
        cta: i.hasAccount ? 'פתיחת האפליקציה' : 'הצטרפות עכשיו',
        hint: i.hasAccount
          ? 'כבר הוספנו אותך — התחבר/י עם החשבון הקיים שלך.'
          : `הירשם/י עם הכתובת <b>${esc(i.to)}</b> ותתווסף/י אוטומטית.`,
        foot: 'קיבלת את המייל כי מישהו הזמין אותך. אם זו טעות — אפשר להתעלם.',
        dir: 'rtl',
        tag: 'האכלות, שינה וחיתולים — משותף',
      }
    : {
        subject: `${i.inviterName} invited you to follow ${i.babyName} 🍼`,
        hi: 'Hi there!',
        lead: `<b>${esc(i.inviterName)}</b> invited you to join <b>${esc(i.babyName)}</b>'s board on BabyDaily.`,
        role: 'Your role',
        what: "What you'll get",
        bullets: ['Feedings, sleep & diapers in real time', 'Alerts whenever something new is logged', 'Effortless sharing across the whole family'],
        cta: i.hasAccount ? 'Open BabyDaily' : 'Join now',
        hint: i.hasAccount
          ? "You've already been added — sign in with your existing account."
          : `Sign up with <b>${esc(i.to)}</b> and you'll be added automatically.`,
        foot: "You're receiving this because someone invited you. If this was a mistake, just ignore it.",
        dir: 'ltr',
        tag: 'Feeding, sleep & diapers — shared',
      };

  const tints = ['#FFF1D1', '#DDF6EC', '#E9E6FF'];
  const icons = ['🍼', '😴', '🧷'];
  const html = `<!doctype html><html lang="${he ? 'he' : 'en'}" dir="${t.dir}"><body style="margin:0;background:#FFF9F4;font-family:'Nunito','Segoe UI',Arial,sans-serif;color:#2B2A3D">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FFF9F4;padding:28px 12px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:28px;overflow:hidden">
<tr><td style="background:#FF7A59;background-image:linear-gradient(135deg,#FF8E6B,#FF6B8B);padding:34px 28px;text-align:center;color:#fff">
<div style="font-size:46px;line-height:1">🍼</div>
<div style="font-size:26px;font-weight:800;margin-top:8px">BabyDaily</div>
<div style="opacity:.92;font-size:14px;margin-top:4px">${t.tag}</div></td></tr>
<tr><td style="padding:30px 28px 8px">
<div style="font-size:20px;font-weight:800;margin-bottom:10px">${t.hi}</div>
<div style="font-size:16px;line-height:1.6">${t.lead}</div>
<div style="margin:20px 0;padding:14px 16px;background:#FFE6DE;border-radius:16px;font-size:14px"><span style="color:#8C8AA0">${t.role}:</span> <b style="color:#FF7A59">${roleText}</b></div>
<div style="font-size:13px;font-weight:800;letter-spacing:.04em;text-transform:uppercase;color:#8C8AA0;margin:6px 0 8px">${t.what}</div>
${t.bullets.map((b, n) => `<div style="padding:10px 14px;margin-bottom:8px;border-radius:14px;background:${tints[n]};font-size:14px;font-weight:700">${icons[n]}&nbsp; ${b}</div>`).join('')}
</td></tr>
<tr><td align="center" style="padding:18px 28px 6px"><a href="${link}" style="display:inline-block;background:#FF7A59;color:#fff;text-decoration:none;font-weight:800;font-size:16px;padding:15px 34px;border-radius:18px">${t.cta}</a></td></tr>
<tr><td style="padding:10px 28px 28px;text-align:center;font-size:13px;color:#8C8AA0;line-height:1.6">${t.hint}</td></tr>
<tr><td style="padding:16px 28px;background:#FFF9F4;text-align:center;font-size:12px;color:#8C8AA0">${t.foot}</td></tr>
</table></td></tr></table></body></html>`;

  const text = he
    ? `${i.inviterName} הזמין/ה אותך לעקוב אחרי ${i.babyName} ב-BabyDaily.\nתפקיד: ${roleText}\n${link}`
    : `${i.inviterName} invited you to follow ${i.babyName} on BabyDaily.\nRole: ${roleText}\n${link}`;

  return { subject: t.subject, html, text };
}

export async function sendInviteEmail(i: InviteMailInput): Promise<MailResult> {
  const { subject, html, text } = renderInviteEmail(i);
  return sendEmail(i.to, subject, html, text);
}

export interface WelcomeMailInput {
  to: string;
  name: string;
  locale: string;
}

/** Branded welcome email following user registration. */
export function renderWelcomeEmail(w: WelcomeMailInput) {
  const he = w.locale === 'he';
  const link = env.APP_URL;

  const t = he
    ? {
        subject: 'ברוכים הבאים לבייבי דיילי! 👶',
        hi: `שלום ${esc(w.name)}!`,
        lead: 'שמחים שהצטרפת ל-<b>BabyDaily</b> — המקום המושלם לניהול שגרת היום של התינוק/ת שלך ביחד עם כל המשפחה.',
        tipsTitle: 'מה אפשר לעשות עכשיו?',
        bullets: [
          'תעדו בקלות: האכלות (הנקה ובקבוק), שעות שינה, חיתולים ותרופות בלחיצה אחת',
          'שתפו שותפים: הזמינו את בן/בת הזוג, מטפלת או סבא וסבתא לעדכונים בזמן אמת',
          'קבלו תזכורות חכמות והפיקו דוחות PDF ו-Excel לרופא הילדים',
        ],
        cta: 'כניסה לאפליקציה',
        foot: 'נרשמת בהצלחה לבייבי דיילי. אם לא נרשמת, צור/י קשר לתמיכה.',
        dir: 'rtl',
        tag: 'האכלות, שינה וחיתולים — משותף',
      }
    : {
        subject: 'Welcome to BabyDaily! 👶',
        hi: `Hello ${esc(w.name)}!`,
        lead: 'Welcome to <b>BabyDaily</b> — the easiest way to track and share your baby routine together with family and caregivers.',
        tipsTitle: 'Quick start tips',
        bullets: [
          'Log in 1 tap: Feedings (breast & bottle), naps, diaper changes, and medicine',
          'Invite family: Partner, nanny, and grandparents stay synced in real time',
          'Set smart reminders and generate pediatric PDF reports',
        ],
        cta: 'Open BabyDaily',
        foot: 'You registered for BabyDaily. If you did not sign up, please contact support.',
        dir: 'ltr',
        tag: 'Feeding, sleep & diapers — shared',
      };

  const icons = ['🍼', '👨‍👩‍👧', '📊'];
  const tints = ['#FFF1D1', '#DDF6EC', '#DFEFFF'];

  const html = `<!doctype html><html lang="${he ? 'he' : 'en'}" dir="${t.dir}"><body style="margin:0;background:#FFF9F4;font-family:'Nunito','Segoe UI',Arial,sans-serif;color:#2B2A3D">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FFF9F4;padding:28px 12px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:28px;overflow:hidden">
<tr><td style="background:#FF7A59;background-image:linear-gradient(135deg,#FF8E6B,#FF6B8B);padding:34px 28px;text-align:center;color:#fff">
<div style="font-size:46px;line-height:1">👶</div>
<div style="font-size:26px;font-weight:800;margin-top:8px">BabyDaily</div>
<div style="opacity:.92;font-size:14px;margin-top:4px">${t.tag}</div></td></tr>
<tr><td style="padding:30px 28px 8px">
<div style="font-size:20px;font-weight:800;margin-bottom:10px">${t.hi}</div>
<div style="font-size:16px;line-height:1.6">${t.lead}</div>
<div style="font-size:13px;font-weight:800;letter-spacing:.04em;text-transform:uppercase;color:#8C8AA0;margin:20px 0 10px">${t.tipsTitle}</div>
${t.bullets.map((b, n) => `<div style="padding:12px 14px;margin-bottom:8px;border-radius:14px;background:${tints[n]};font-size:14px;font-weight:700">${icons[n]}&nbsp; ${b}</div>`).join('')}
</td></tr>
<tr><td align="center" style="padding:18px 28px 24px"><a href="${link}" style="display:inline-block;background:#FF7A59;color:#fff;text-decoration:none;font-weight:800;font-size:16px;padding:15px 34px;border-radius:18px">${t.cta}</a></td></tr>
<tr><td style="padding:16px 28px;background:#FFF9F4;text-align:center;font-size:12px;color:#8C8AA0">${t.foot}</td></tr>
</table></td></tr></table></body></html>`;

  const text = he
    ? `שלום ${w.name}!\nברוכים הבאים ל-BabyDaily.\n${t.lead.replace(/<[^>]+>/g, '')}\n${link}`
    : `Hello ${w.name}!\nWelcome to BabyDaily.\n${t.lead.replace(/<[^>]+>/g, '')}\n${link}`;

  return { subject: t.subject, html, text };
}

export async function sendWelcomeEmail(w: WelcomeMailInput): Promise<MailResult> {
  const { subject, html, text } = renderWelcomeEmail(w);
  return sendEmail(w.to, subject, html, text);
}

export interface PasswordResetMailInput {
  to: string;
  name: string;
  resetToken: string;
  locale: string;
}

/** Branded password reset recovery email. */
export function renderPasswordResetEmail(p: PasswordResetMailInput) {
  const he = p.locale === 'he';
  const link = `${env.APP_URL}/?resetToken=${encodeURIComponent(p.resetToken)}&email=${encodeURIComponent(p.to)}`;

  const t = he
    ? {
        subject: 'איפוס סיסמה — בייבי דיילי 🔐',
        hi: `שלום ${esc(p.name)}!`,
        lead: 'קיבלנו בקשה לאיפוס הסיסמה לחשבון שלך ב-BabyDaily.',
        actionText: 'לחצ/י על הכפתור למטה כדי להגדיר סיסמה חדשה (הקישור בתוקף למשך שעה אחת):',
        cta: 'איפוס סיסמה עכשיו',
        hint: 'אם לא ביקשת לאפס את הסיסמה, אפשר להתעלם מהודעה זו והסיסמה הנוכחית תישאר בתוקף.',
        foot: 'קיבלת הודעה זו בעקבות בקשת שחזור סיסמה.',
        dir: 'rtl',
        tag: 'איפוס סיסמה מאובטח',
      }
    : {
        subject: 'Password Reset — BabyDaily 🔐',
        hi: `Hello ${esc(p.name)}!`,
        lead: 'We received a request to reset your BabyDaily account password.',
        actionText: 'Click the button below to set a new password (link valid for 1 hour):',
        cta: 'Reset Password',
        hint: 'If you did not request this, you can safely ignore this email — your current password remains unchanged.',
        foot: 'You received this email because a password reset was initiated.',
        dir: 'ltr',
        tag: 'Secure Password Reset',
      };

  const html = `<!doctype html><html lang="${he ? 'he' : 'en'}" dir="${t.dir}"><body style="margin:0;background:#FFF9F4;font-family:'Nunito','Segoe UI',Arial,sans-serif;color:#2B2A3D">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FFF9F4;padding:28px 12px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:28px;overflow:hidden">
<tr><td style="background:#FF7A59;background-image:linear-gradient(135deg,#FF8E6B,#FF6B8B);padding:34px 28px;text-align:center;color:#fff">
<div style="font-size:46px;line-height:1">🔐</div>
<div style="font-size:26px;font-weight:800;margin-top:8px">BabyDaily</div>
<div style="opacity:.92;font-size:14px;margin-top:4px">${t.tag}</div></td></tr>
<tr><td style="padding:30px 28px 8px">
<div style="font-size:20px;font-weight:800;margin-bottom:10px">${t.hi}</div>
<div style="font-size:16px;line-height:1.6">${t.lead}</div>
<div style="margin:18px 0;font-size:14px;color:#8C8AA0;line-height:1.5">${t.actionText}</div>
</td></tr>
<tr><td align="center" style="padding:14px 28px 10px"><a href="${link}" style="display:inline-block;background:#FF7A59;color:#fff;text-decoration:none;font-weight:800;font-size:16px;padding:15px 34px;border-radius:18px">${t.cta}</a></td></tr>
<tr><td style="padding:12px 28px 24px;text-align:center;font-size:13px;color:#8C8AA0;line-height:1.6">${t.hint}</td></tr>
<tr><td style="padding:16px 28px;background:#FFF9F4;text-align:center;font-size:12px;color:#8C8AA0">${t.foot}</td></tr>
</table></td></tr></table></body></html>`;

  const text = he
    ? `שלום ${p.name}!\n${t.lead}\n${t.actionText}\n${link}\n${t.hint}`
    : `Hello ${p.name}!\n${t.lead}\n${t.actionText}\n${link}\n${t.hint}`;

  return { subject: t.subject, html, text };
}

export async function sendPasswordResetEmail(p: PasswordResetMailInput): Promise<MailResult> {
  const { subject, html, text } = renderPasswordResetEmail(p);
  return sendEmail(p.to, subject, html, text);
}
