# API Conventions & Contracts

## Endpoints Summary

### Authentication
- `POST /auth/register`: Create user account (`name`, `email`, `password`, optional `phone`, `locale`).
- `POST /auth/login`: Sign in with email OR phone identifier + password.
- `GET /me`: Current user profile.
- `PATCH /me`: Update profile (name, locale, phone).

### Babies & Memberships
- `GET /babies`: List all babies the current user has access to.
- `POST /babies`: Create a new baby (user is automatically granted OWNER role).
- `GET /babies/:babyId`: Details of a baby.
- `PATCH /babies/:babyId`: Update baby name, birth date, avatar color (OWNER only).
- `DELETE /babies/:babyId`: Delete baby and cascade all related data (OWNER only).
- `GET /babies/:babyId/members`: List all members and their roles.

### Daily Activities & Entries
- `GET /babies/:babyId/entries`: Fetch activity timeline (supports filtering by `type`, date range, limit).
- `POST /babies/:babyId/entries`: Log an event (FEED, SLEEP, DIAPER, GROWTH, MEDICINE, NOTE). Automatically triggers notification fanout and reminder reschedule.
- `PATCH /entries/:id`: Edit entry or end an active sleep (triggers "Baby woke up" notification).
- `DELETE /entries/:id`: Remove entry.
- `GET /babies/:babyId/summary`: Computed daily metrics for local midnight (`from` / `to`).

### Sharing & Invitations
- `GET /babies/:babyId/invitations`: List pending invites for baby (OWNER only).
- `POST /babies/:babyId/invitations`: Invite by email or phone with role `CAREGIVER` or `VIEWER`.
- `DELETE /invitations/:id`: Revoke pending invite.
- `GET /invitations`: List pending invites sent to current user.
- `POST /invitations/:id/accept`: Accept invitation and join baby.
- `POST /invitations/:id/decline`: Decline invitation.
- `DELETE /babies/:babyId/members/:memberId`: Remove follower.

### Reminders & Alerts
- `GET /babies/:babyId/reminders`: List personal reminders for baby.
- `POST /babies/:babyId/reminders`: Create reminder (`AFTER_LAST` or `DAILY_AT`).
- `DELETE /reminders/:id`: Delete reminder.
- `GET /notifications`: In-app notification center inbox.
- `POST /notifications/read-all`: Mark all as read.
- `POST /notifications/:id/read`: Mark single notification as read.
- `POST /devices`: Register FCM push token for mobile/web push alerts.
