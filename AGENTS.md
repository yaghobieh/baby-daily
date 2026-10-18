# BabyDaily — Engineering & Architecture Rules

This repository contains **BabyDaily**, a multi-platform parenting companion (Flutter for iOS/Android/Web + Node.js Fastify + Prisma ORM + PostgreSQL on Neon).

---

## 1. Core Architecture Principles

1. **Clean Separation of Concerns**:
   - `backend/`: Fastify REST API, Prisma schema, PostgreSQL connection, Push/In-App Notification service, Reminder cron engine.
   - `app/`: Flutter multi-platform client (iOS, Android, Web) using Provider state management, Material 3 pastel design, and bilingual L10N (English & Hebrew with RTL).

2. **Database & ORM Rules**:
   - PostgreSQL hosted on **Neon Serverless Postgres**.
   - Always split the Neon connection into:
     - `DATABASE_URL`: Pooled connection string (`-pooler` domain with `pgbouncer=true`) for application runtime queries.
     - `DIRECT_URL`: Direct non-pooled connection for migrations (`prisma migrate`).
   - Every timestamp column must store UTC (`DateTime @default(now())`).
   - Primary keys must be CUID strings (`@default(cuid())`).
   - Foreign key cascading deletes must be explicit (`onDelete: Cascade` or `onDelete: SetNull`).

3. **Timezone & Date Conventions**:
   - Store all event times (`startedAt`, `endedAt`, `createdAt`) in **UTC**.
   - Client sends its device `utcOffset` in minutes upon login/register.
   - The daily overview endpoint (`/babies/:babyId/summary`) accepts `from` and `to` query parameters computed by the client based on the user's local midnight.

---

## 2. Security & Role-Based Access Control (RBAC)

1. **Three Member Roles**:
   - `OWNER`: Full administrative rights (invite caregivers/viewers, revoke invites, edit baby profile, delete baby).
   - `CAREGIVER`: Can log, edit, and delete entries (feeding, sleep, diaper, medicine, growth, notes).
   - `VIEWER`: Read-only follower. Receives notifications and views timeline and daily stats.

2. **Contact & Invite Matching**:
   - Users can be invited by **Email** or **Phone Number**.
   - Phone numbers are normalized: last 9 digits are stored as `phoneKey` to ensure international vs. local formats match seamlessly.
   - If an invited contact already has an account, they immediately receive an in-app notification.
   - If the contact signs up later with that email or phone, their pending invitations automatically appear in "Invitations For You".

3. **JWT Authentication**:
   - Stateless 60-day tokens signed with `JWT_SECRET`.
   - Client persists token securely in `SharedPreferences` and attaches `Authorization: Bearer <token>`.
   - Never return `passwordHash` in any API response.

---

## 3. Real-time Notifications & Reminders

1. **Push & In-App Fanout**:
   - Whenever an entry is logged, all active members of the baby (except the actor) who opted into that entry type receive a notification.
   - When an active sleep ends, a "Baby woke up" alert is sent with duration (e.g. "Liam woke up: slept 1h 20m").
   - Quiet hours are respected per member: notifications during quiet hours are stored in-app without triggering sound/vibration push.

2. **Smart Reminders Engine**:
   - `AFTER_LAST`: Triggers N minutes after the last entry of that type (e.g. 3 hours after last feed). Rescheduled automatically whenever an entry is logged or updated.
   - `DAILY_AT`: Triggers daily at a fixed time (e.g. Vitamin D at 10:00 AM).

---

## 4. Flutter UI & UX Guidelines

1. **Aesthetics ("Easy & Beauty")**:
   - Soft pastel parenting palette: Warm coral (`#FF7A7A`), soft mint (`#48C78E`), lavender (`#8C7AE6`), sunny amber (`#FFAA00`), and sky blue (`#3897F0`).
   - Generous border radius (16-24px), subtle shadows, clean card hierarchy.
   - Prominent live ticker when baby is sleeping with instant "Wake Up" action.

2. **Bilingual & RTL**:
   - Full support for **English** and **Hebrew**.
   - Hebrew triggers automatic RTL directionality (`Directionality` / `GlobalWidgetsLocalizations`).
