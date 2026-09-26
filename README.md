# EventCrew

A production-minded **Flutter + Supabase event staffing app** built as a focused
vertical slice of a real workforce workflow:

**discover shifts → join / waitlist → clock in/out → team chat → notifications**

**Flutter · Riverpod · go_router · Supabase Auth/PostgreSQL/RLS/Realtime · Firebase Cloud Messaging**

> Portfolio goal: demonstrate how I would safely extend an existing staffing
> app — incremental feature delivery, server-side business invariants, realtime
> communication, push integration boundaries, tests, and CI.

## Product workflow

- **My shifts / Available shifts** with Confirmed and Waitlisted states
- Capacity meter and automatic waitlist promotion
- Server-authoritative clock in/out restored after navigation or reload
- Event-only realtime chat with staff name, role, and initials/avatar fallback
- Optional FCM device registration for shift reminders and operational alerts
- Loading, empty, validation, and user-safe error states

## Staffing rules live on the server

Flutter does not decide who gets the last shift place.

- `join_event()` locks the event row before assigning Confirmed or Waitlisted
- `leave_event()` blocks active clock-ins and promotes the oldest waitlisted staff
- one membership per user/event remains database-enforced
- one active clock-in per user/event remains database-enforced
- attendance timestamps are assigned/protected by PostgreSQL
- profile RLS exposes staff identity only to people sharing an event
- event chat remains member-only

This protects the workflow across concurrent devices, retries, and stale clients.

## Push notification boundary

The app registers the authenticated device's FCM token in `device_tokens`
only when Firebase configuration is supplied. Firebase credentials are optional,
so the Web portfolio build still works without push configuration.

Notification sending happens in:

`supabase/functions/send-shift-notification/index.ts`

The Edge Function uses a Firebase service account stored in server-side secrets,
sends through FCM HTTP v1, and records an auditable row in `notifications`.
No service credential is shipped in Flutter.

## Design system

The v2 UI is backed by a dedicated Figma file:

**EventCrew — Staffing Mobile Design System**

https://www.figma.com/design/rDzvFUgqmI5ZnT1JhYRm40

It contains EventCrew color/spacing/radius tokens, reusable staffing components,
and four mobile screens:

- Event list
- Shift detail
- Clock-in
- Team chat

The same core values are mirrored in `AppTheme` so the design is intended to
round-trip into Flutter rather than remain a disconnected mockup.

## Architecture

```text
Flutter UI
  → Riverpod providers/controllers
    → feature repositories/services
      → Supabase Auth / PostgreSQL + RLS / Realtime
      → Firebase Messaging (device token + foreground delivery)

Trusted ops backend
  → Supabase Edge Function
    → FCM HTTP v1
    → notification audit row
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Why this maps to an event-staffing role

| Job need | Evidence in this repo |
| --- | --- |
| Strong Flutter | Feature-based UI, Riverpod, navigation, async/operational states |
| Strong Supabase | Auth, RLS, RPCs, migrations, Realtime |
| SQL/PostgreSQL | Constraints, indexes, triggers, locking, waitlist promotion |
| Realtime | Event-scoped chat subscription with lifecycle cleanup |
| Push notifications | FCM token lifecycle + trusted Edge Function dispatcher |
| Existing-codebase work | Incremental features without replacing the architecture |
| Reliability | Server-side invariants + unit/widget tests + CI |
| UI/UX | Shared Figma/Flutter tokens and staffing-specific components |

## Run locally

Requires **Flutter 3.27+ / Dart 3.6+** and Supabase.

Run migrations in order:

1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_operational_guardrails.sql`
3. `supabase/migrations/003_staffing_operations_v2.sql`
4. `supabase/seed.sql`

Create a Supabase Auth demo user, then:

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

### Optional Firebase Messaging configuration

Native/Web push is enabled only when these compile-time values are supplied:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_AUTH_DOMAIN          # optional
FIREBASE_STORAGE_BUCKET       # optional
FIREBASE_VAPID_KEY            # Web token registration
```

For the Edge Function, configure server-side secrets:

```text
FIREBASE_SERVICE_ACCOUNT
NOTIFICATION_DISPATCH_SECRET
```

Never place the Firebase service account in Flutter or in the repository.

## Demo script

1. Sign in.
2. Join an event with open capacity and see **Confirmed**.
3. Fill an event to capacity with other demo users; the next user joins as **Waitlisted**.
4. Remove a confirmed user and verify the oldest waitlisted user is promoted.
5. Clock in and reload; attendance persists from PostgreSQL.
6. Open Team Chat from two users and verify names/roles + realtime inserts.
7. With Firebase configured, register the device and dispatch a test shift alert
   through the trusted Edge Function.

## Quality checks

Every pull request targeting `master` runs:

```bash
flutter analyze
flutter test
flutter build web --release
```

## Next production increments

- Admin/ops UI for publishing shifts and sending broadcasts
- Native Android/iOS signing and store pipelines
- Crash reporting and product analytics
- Offline/retry UX for attendance and chat
- Notification inbox screen and deep-link handling
