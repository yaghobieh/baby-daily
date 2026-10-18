# 🍼 BabyDaily (בייבי דיילי)

> Modern, beautiful, and effortless daily baby routine tracker with real-time sharing (Email / Phone) and smart notifications. Multi-platform Flutter (iOS, Android, Web) backed by Fastify, Prisma ORM, and Neon Serverless PostgreSQL.

---

## ✨ Features

- **Daily Routine Tracking**:
  - 🍼 **Feeding**: Breastfeeding (side tracker), Bottle (ml amount), Solids (food description).
  - 😴 **Sleep**: Live nap ticker with one-tap "Wake Up" alert ("Baby woke up: slept 1h 20m").
  - 🧷 **Diapers**: Wet, Dirty, Mixed, Dry.
  - 📏 **Growth**: Weight (kg), Height (cm), Head circumference (cm).
  - 💊 **Medicine & Vaccines**: Name, dosage, vaccination logs.
  - 📝 **Notes & Moods**: Quick mood picker (Happy, Calm, Fussy, Crying, Sick) with notes.

- **Sharing with Loved Ones (Core Feature)**:
  - Invite by **Email** or **Phone Number**.
  - Roles: `Caregiver` (can log entries) or `Viewer` (read-only follower).
  - Normalizes international vs. local phone formatting so invites always match seamlessly.
  - In-app invitation acceptance & follower management.
  - Removal of followers with immediate access revocation.
  - Automatic welcome email simulation upon registration with complete baby summary.

- **📊 Data Export (CSV, PDF, Word)**:
  - **Excel / Google Sheets (CSV)**: UTF-8 BOM encoded spreadsheet with full event logs, timestamps, authors, and notes in Hebrew & English.
  - **Pediatrician Printout (PDF)**: Medical-grade printable A4 report with stats breakdown, growth metrics, and formatted activity table.
  - **Microsoft Word (.DOC)**: Clean editable HTML-based document ready to open and customize in Microsoft Word or Google Docs.

- **📲 Multi-Channel Sharing & Notifications**:
  - **WhatsApp**: Pre-formatted daily routine summary and direct test alerts via `wa.me`.
  - **Telegram**: Instant routine sharing via Telegram share API.
  - **In-App & Push**: Real-time notification inbox with badges and instant delivery.
  - **SMS Simulation**: Clean international and Israeli phone normalization with multi-channel dispatch.
  - **Send to All**: 1-tap dispatch delivering across push, SMS, WhatsApp, and Telegram simultaneously.

- **🎨 Dynamic Theme Colors & Hebrew RTL**:
  - Full app-wide color personalization from Settings (Coral, Mint, Lavender, Sky Blue, Sunny Amber, Blush Rose).
  - Complete Hebrew and English localization with automatic Right-to-Left (RTL) mirroring.
  - Proper title casing validation for English names (e.g., `eYAER` -> `Eyaer`).

---


## 🎨 2026 Modern Redesign & UI System
- **Color System**: Curated Nunito soft-tint palette (Primary Coral , Feeding Amber , Sleep Mint , Diaper Lavender , Medicine Rose , Growth Sky , Note Teal ).
- **Dark Mode**: Full dark theme with 🌓 toggle, mode-aware card surfaces, and low-contrast palettes designed for midnight feedings.
- **Recent Activity Filters**: Instant interactive filter chips (All, Feeding, Sleep, Diaper, Medicine, Growth, Note).
- **Settings & Channels**: Dedicated WhatsApp and Telegram toggles with SMS deactivated in favor of responsive branded email templates.
- **Store Graphics**: High-res icons (1024x1024), Play Store feature graphics (1024x500), and banner assets located in `branding/`.
- **Store Listing & Release**: See [STORE_LISTING.md](STORE_LISTING.md) and [RELEASE.md](RELEASE.md).

## 🚀 Vercel Deployment
The backend Fastify server is configured as a Vercel Serverless Function (`backend/vercel.json`).
- Production API URL defaults to `https://baby-daily-api.vercel.app` (or `--dart-define=API_URL=...`).
- Debug builds automatically fallback to local backend on `http://localhost:5050` or `http://<host>:5050` over Wi-Fi.

## 🗄️ Database (Neon PostgreSQL)

Connected to your Neon Postgres database:
- **Runtime queries**: Pooled connection with PgBouncer (`DATABASE_URL`).
- **Prisma migrations**: Direct connection (`DIRECT_URL`).

Schema includes: `User`, `Baby`, `BabyMember`, `Invitation`, `Entry`, `Reminder`, `Notification`, `DeviceToken`, `Photo`.

---

## 🚀 Quick Start

### 1. Start the Backend API

```bash
cd backend
npm install
npm run build
npm run dev
```

The API starts on `http://localhost:5050`.

Verify server health:
```bash
curl http://localhost:5050/health
# {"ok":true,"time":"..."}
```

### 2. Testing Notifications via curl

You can trigger a test notification directly without logging in or using an authorization token by passing your phone number:

```bash
curl -X POST http://localhost:5050/notifications/test \
  -H "Content-Type: application/json" \
  -d '{"phone": "+972544481412", "title": "בדיקת התראה 🍼", "body": "שלום! התראת בדיקה נשלחה בהצלחה למכשיר שלך."}'
```

Output:
```json
{
  "ok": true,
  "sentToUserId": "cmvdjeeag0000f8rk2lhfsli0",
  "phone": "0544481412",
  "channel": "all",
  "title": "בדיקת התראה 🍼",
  "body": "שלום! התראת בדיקה נשלחה בהצלחה למכשיר שלך.",
  "whatsappUrl": "https://wa.me/0544481412?text=...",
  "telegramUrl": "https://t.me/share/url?text=...",
  "delivered": { "push": true, "sms": true, "whatsapp": true, "telegram": true }
}
```

### 3. Run the Flutter App

#### On Web (Chrome):
```bash
cd app
flutter run -d chrome
```

#### On iOS Simulator:
```bash
cd app
flutter run -d "iPhone 16"
```

#### On Android Emulator:
```bash
cd app
flutter run -d emulator
```

*(Note: In the app settings tab, you can customize the API Server URL if testing across a local Wi-Fi network on physical devices).*

---

## 📁 Project Structure

```
baby-daily/
├── AGENTS.md                  # Architectural guidelines & AI conventions
├── README.md                  # This file
├── .agents/
│   └── rules/
│       ├── coding-standards.md
│       └── api-conventions.md
├── backend/                   # Fastify + TypeScript + Prisma + Neon DB
│   ├── .env                   # Neon database connection strings & JWT secret
│   ├── .env.example           # Sanitized environment template
│   ├── prisma/
│   │   └── schema.prisma      # Prisma PostgreSQL schema
│   └── src/
│       ├── server.ts          # Fastify server entry point
│       ├── schemas.ts         # Zod schemas for all requests
│       ├── routes/            # Auth, Babies, Sharing, Entries, Reminders, Misc
│       └── services/          # Push notify fanout & reminder cron engine
└── app/                       # Flutter App (iOS, Android, Web)
    ├── pubspec.yaml
    └── lib/
        ├── api/               # Typed HTTP client & token manager
        ├── models/            # User, Baby, Entry, Invitation, Reminder
        ├── state/             # Provider state managers
        ├── l10n/              # English & Hebrew string dictionary
        ├── theme/             # Soft pastel Material 3 theme & dynamic color manager
        ├── widgets/           # StatCards, QuickActionButton, EntryCard, Avatar
        └── screens/           # Auth, Home, Sharing, Reminders, Notifications, Settings
```
