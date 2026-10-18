import type { EntryType } from '@prisma/client';

type Locale = 'en' | 'he';
const pick = (locale: string): Locale => (locale === 'he' ? 'he' : 'en');

const ENTRY_EMOJI: Record<EntryType, string> = {
  FEED: '🍼',
  SLEEP: '😴',
  DIAPER: '🧷',
  GROWTH: '📏',
  MEDICINE: '💊',
  NOTE: '📝',
};

const ENTRY_LABEL: Record<Locale, Record<EntryType, string>> = {
  en: {
    FEED: 'a feeding',
    SLEEP: 'sleep',
    DIAPER: 'a diaper change',
    GROWTH: 'a growth measurement',
    MEDICINE: 'medicine',
    NOTE: 'a note',
  },
  he: {
    FEED: 'האכלה',
    SLEEP: 'שינה',
    DIAPER: 'החלפת חיתול',
    GROWTH: 'מדידת גדילה',
    MEDICINE: 'תרופה',
    NOTE: 'הערה',
  },
};

/** Server-side push/in-app strings. Keep in sync with app/lib/l10n/*.arb tone. */
export const t = {
  entryLogged(locale: string, type: EntryType, actor: string, baby: string) {
    const l = pick(locale);
    const label = ENTRY_LABEL[l][type];
    return l === 'he'
      ? { title: `${ENTRY_EMOJI[type]} ${baby}`, body: `${actor} רשם/ה ${label}` }
      : { title: `${ENTRY_EMOJI[type]} ${baby}`, body: `${actor} logged ${label}` };
  },
  sleepEnded(locale: string, actor: string, baby: string, minutes: number) {
    const l = pick(locale);
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    const dur = h > 0 ? `${h}h ${m}m` : `${m}m`;
    return l === 'he'
      ? { title: `🌤️ ${baby} התעורר/ה`, body: `${actor}: ישן/ה ${dur}` }
      : { title: `🌤️ ${baby} woke up`, body: `${actor}: slept ${dur}` };
  },
  invited(locale: string, actor: string, baby: string) {
    return pick(locale) === 'he'
      ? { title: '💌 הזמנה חדשה', body: `${actor} הזמין/ה אותך לעקוב אחרי ${baby}` }
      : { title: '💌 New invitation', body: `${actor} invited you to follow ${baby}` };
  },
  inviteAccepted(locale: string, who: string, baby: string) {
    return pick(locale) === 'he'
      ? { title: '🎉 הצטרפות', body: `${who} מצטרף/ת למעקב אחרי ${baby}` }
      : { title: '🎉 Joined', body: `${who} is now following ${baby}` };
  },
  reminder(locale: string, title: string, baby: string) {
    return pick(locale) === 'he'
      ? { title: `⏰ ${baby}`, body: title }
      : { title: `⏰ ${baby}`, body: title };
  },
};
