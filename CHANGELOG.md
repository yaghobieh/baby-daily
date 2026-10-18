# 📋 BabyDaily Changelog

All notable changes to the BabyDaily project are documented in this file.

## [1.0.0] - 2026-10-18

### 🚀 Initial Production Release

#### 🍼 Daily Routine Tracker
- Complete activity tracking: **Feeding** (Breastfeeding, Bottle, Solids), **Sleep** (Live timer ticker & wake-up alerts), **Diapers** (Wet, Dirty, Mixed, Dry), **Growth** (Weight, Height, Head circumference), **Medicine & Vaccines**, and **Mood Notes**.
- Instant summary cards displaying daily feeding volumes, sleep totals, and diaper change counts.

#### 🤝 Loved Ones Sharing (Core Feature)
- Seamless invitation system using **Email** or **Phone Number**.
- Role-based access control (`Caregiver` vs `Viewer`).
- One-tap removal of followers with immediate revocation of baby routine access.
- Registration welcome email simulation sending a complete baby routine overview.

#### 📊 Multi-Format Data Export
- **CSV**: UTF-8 BOM formatted spreadsheet compatible with Excel and Google Sheets.
- **PDF**: Medical-grade printable pediatric health and milestone report.
- **Word (.DOC)**: Clean editable HTML-based document ready for Microsoft Word and Google Docs.

#### 📲 Multi-Channel Notifications & Sharing
- Direct **WhatsApp** routine summary sharing via `wa.me`.
- Direct **Telegram** routine sharing.
- Push and In-App notification center with unread badge tracking.
- Test notification endpoint supporting simulated SMS, WhatsApp link, Telegram link, and "Send All Channels".

#### 🎨 Localization & Theming
- Full bilingual support in **Hebrew** (עברית with complete RTL layout) and **English**.
- App-wide dynamic theme customization from Settings (Coral, Mint, Lavender, Sky Blue, Sunny Amber, Blush Rose).
- Strict name validation with auto-capitalization (e.g., `eYAER` -> `Eyaer`).

#### 🗄️ Backend Infrastructure
- Fastify + TypeScript backend connected to Neon Serverless PostgreSQL with Prisma ORM.
- Pooled connection runtime + Direct URL for migrations.
