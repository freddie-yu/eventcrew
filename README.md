# EventCrew

A production-minded **Flutter + Supabase event staffing app** built as a focused
vertical slice of a real workforce workflow:

**sign in → discover shifts → join → clock in/out → team chat → leave shift**

**Flutter · Riverpod · go_router · Supabase Auth · PostgreSQL/RLS · Realtime**

> Portfolio goal: demonstrate the skills needed to extend an existing staffing
> app safely — feature delivery, state management, Supabase/Postgres data
> integrity, realtime lifecycle management, tests, and CI — rather than build a
> disposable UI prototype.

## Product workflow

### Staff-facing

- **My shifts / Available shifts** separation for fast operational scanning
- Join an open event once; duplicate membership is blocked by PostgreSQL
- Leave a shift safely when not actively clocked in
- Clock in/out with attendance restored from PostgreSQL after navigation/reload
- Event-only realtime team chat with the latest 50 messages
- Loading, empty, validation, and user-safe error states

### Data integrity

Important rules live in Supabase/PostgreSQL, not only in Flutter:

- RLS limits user-owned membership and attendance records
- event chat is accessible only to event members
- a unique constraint prevents duplicate shift joins
- a partial unique index prevents concurrent double clock-ins
- database triggers own attendance timestamps and block rewrites/reopens
- shift leave is rejected while an active clock-in exists
- expired events cannot be joined
- chat messages must be non-empty and are capped at 1000 characters

This keeps invariants intact across multiple devices, retries, stale UI, and
concurrent requests.

## Architecture

```text
Flutter screens
  → Riverpod providers/controllers
    → feature repositories
      → Supabase Auth
      → PostgreSQL + RLS
      → Supabase Realtime
```

Code is grouped by feature under `lib/features/`, with routing/configuration,
error mapping, theme, and Supabase dependency injection under `lib/core/`.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the design decisions and
server-side invariants.

## Why this maps to an event-staffing role

| Job need | Evidence in this repo |
| --- | --- |
| Strong Flutter | Feature-based UI, Material 3, forms, async states, navigation |
| Strong Supabase | Auth, Postgres, RLS, migrations, Realtime |
| SQL/PostgreSQL | Constraints, indexes, triggers, policies, seed data |
| Realtime | Event-scoped Postgres INSERT subscription with cleanup |
| Existing-codebase work | Repository/provider boundaries and incremental migrations |
| Performance/reliability | Scoped queries, latest-50 chat history, no global channels |
| Bug prevention | Server-side invariants + unit/widget tests + CI |
| UI/UX sense | Operational states, clear shift grouping, confirmations/errors |

## Run locally

Requires **Flutter 3.27+** and a Supabase project.

This repository currently includes Web scaffolding. To add Android/iOS platform
folders for local device builds, run:

```bash
flutter create .
```

Then:

1. In **Supabase → SQL Editor**, run migrations in order:
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_operational_guardrails.sql`
2. Run `supabase/seed.sql`.
3. In **Authentication → Users**, create a demo user with email/password.
4. Start the app:

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

The publishable/anon key is client-side configuration; authorization is enforced
through RLS. Missing configuration produces a clear setup screen instead of a
runtime crash.

## Demo script

A reviewer can validate the core workflow in a few minutes:

1. Sign in.
2. Join a card under **Available shifts**.
3. Confirm it moves to **My shifts**.
4. Open the shift and clock in.
5. Reload/navigate away and return; attendance remains active from Postgres.
6. Open **Team Chat** and send a message.
7. Try to leave while clocked in; the database rejects it.
8. Clock out and leave the shift successfully.
9. With a second user/device, join the same event and verify realtime chat.

## Quality checks

Every pull request targeting `master` runs:

```bash
flutter analyze
flutter test
flutter build web --release
```

The repository includes model tests and widget tests for authentication
validation, event states, attendance states, and error mapping.

## Deploy Web

Build with the same Supabase values:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

Deploy `build/web` to a static host and configure SPA fallback to
`index.html`.

## Next production increments

The next features are intentionally prioritized around event-staffing operations:

1. **Push notifications** — shift reminders, schedule changes, urgent broadcast
2. **Staff identity in chat** — profile name/avatar with member-aware RLS
3. **Capacity + waitlist** — event staffing limits and promotion workflow
4. **Admin/ops workflow** — publish shifts, inspect attendance, broadcast updates
5. **Native release pipeline** — Android/iOS folders, signing, store CI
6. **Observability** — crash/error reporting and basic product analytics
7. **Offline/retry behavior** — connectivity-aware attendance and message UX

Self-service registration is deliberately not a priority for this demo because
many staffing products provision or invite workers through an admin/HR workflow.
It can be added with Supabase Auth if the target product requires it.

## Current scope

This is a portfolio-ready staffing vertical slice, not a clone of any employer's
proprietary application. It uses synthetic event data and demonstrates an
implementation approach that can be adapted to an existing production codebase.
