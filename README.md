# EventCrew

Flutter + Supabase staffing workflow demonstrating event signup,
secure attendance tracking, and realtime event communication.

Live Demo: `<later>`
Demo Credentials: `<later>`

Flutter · Supabase Auth · PostgreSQL · RLS · Realtime · Riverpod

---

This is a hiring demo for a staffing-app role, built to show a working,
production-shaped vertical slice rather than breadth of features:

**Sign in → browse events → join a shift → clock in/out → realtime team chat.**

## Screenshot

_placeholder — drop a screenshot or short screen recording of the event
list, shift detail (with the attendance panel), and chat screen here
once you have a running Supabase project to demo against._

## Features

- **Email/password sign in** via Supabase Auth, with client-side form
  validation and friendly error messages.
- **Upcoming events list** loaded from PostgreSQL, each showing title,
  date/time, location, and a membership badge (`Available` /
  `Confirmed`).
- **Join a shift** once — a database-level unique constraint prevents
  duplicate membership, not just a client-side check.
- **Shift detail** with start/end time, location, description, and an
  attendance panel.
- **Clock in / clock out**, restored from Supabase on every load — there
  is no local-only "I'm clocked in" flag. A partial unique index
  guarantees at most one active entry per user per event.
- **Team chat**, scoped to the current event, loading only the latest 50
  messages and receiving new ones in realtime without a manual refresh.
  The realtime subscription is torn down automatically when you leave
  the chat screen.
- **Row Level Security** on every table — the client's anon key alone
  never grants access to another user's data.
- Loading / empty / error states on every network-backed screen, with
  no raw Supabase/Postgres error text ever shown to the user.

## Architecture

Feature-first structure, Riverpod for state, go_router for navigation,
Supabase for auth/data/realtime:

```text
lib/
├── main.dart                   # Supabase.initialize + runApp
├── app.dart                    # MaterialApp.router + missing-config gate
├── core/
│   ├── config/env.dart         # compile-time SUPABASE_URL / ANON_KEY
│   ├── error/                  # AppFailure + shared unique-violation mapper
│   ├── router/app_router.dart  # go_router + auth-based redirects
│   ├── supabase/               # SupabaseClient provider
│   └── theme/                  # ThemeData
├── features/
│   ├── auth/        (data: AuthRepository · presentation: sign in screen)
│   ├── events/       (data: EventsRepository · presentation: list/detail)
│   ├── attendance/   (data: AttendanceRepository · presentation: clock in/out)
│   └── chat/         (data: ChatRepository · presentation: realtime chat)
└── shared/widgets/              # AsyncValueView, EmptyState, StatusBadge
```

```text
                         ┌──────────────────────┐
                         │        Flutter        │
                         │  (Riverpod + go_router)│
                         └───────────┬────────────┘
                                     │ supabase_flutter
                                     ▼
                         ┌──────────────────────┐
                         │   Supabase Auth       │  sign in / session
                         ├──────────────────────┤
                         │   PostgreSQL + RLS    │  events, event_members,
                         │                        │  time_entries, messages
                         ├──────────────────────┤
                         │   Realtime            │  INSERT on messages,
                         │                        │  filtered by event_id
                         └──────────────────────┘
```

Each feature has a thin `data/` repository that talks to Supabase and
translates errors into a friendly `AppFailure`, and a `presentation/`
layer of Riverpod providers + widgets. There's no extra domain/use-case
layer — for four tables and four screens it would add indirection
without adding safety, since RLS (not the client) is the real
authorization boundary.

## Local setup

1. Install Flutter (3.19+) and Dart (3.3+).
2. `flutter pub get`
3. Run with your Supabase project's URL and anon key supplied at compile
   time — they are **not** read from a `.env` file or hardcoded:

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

   For a repeatable web build:

   ```bash
   flutter build web \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

   Without both values, the app intentionally shows a "Supabase
   configuration missing" screen instead of crashing or silently doing
   nothing — see `core/config/env.dart` and `app.dart`.

   If your local Flutter SDK needs platform folders this repo doesn't
   include (e.g. `android/`, `ios/` — only `web/` is included here),
   run `flutter create .` once in the repo root; it fills in missing
   platform scaffolding without touching `lib/` or `pubspec.yaml`.

## Supabase setup

1. Create a Supabase project.
2. Run the migration against it (Supabase CLI or paste into the SQL
   editor):

   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```

   or simply paste `supabase/migrations/001_initial_schema.sql` into the
   Supabase Studio SQL editor and run it.
3. Run `supabase/seed.sql` the same way to create four sample events.
4. Create at least one user (Studio → Authentication → Add user, or your
   own sign-up flow) to sign in with — see **Known limitations** below,
   sign-up isn't part of this MVP.
5. Confirm Realtime is enabled for the `messages` table (the migration
   adds it to the `supabase_realtime` publication automatically; verify
   under Database → Replication if messages don't arrive live).

## Demo flow

1. Sign in with a user you created in Supabase.
2. The events list loads from PostgreSQL — seeded events show
   `Available` with a `Join Shift` button.
3. Tap **Join Shift**. The event flips to `Confirmed` everywhere it's
   shown; joining the same event again is blocked by the database, not
   just the UI.
4. Open the shift — **Clock In**. The button, badge, and elapsed timer
   all come from the persisted `time_entries` row. Reload the app: the
   clocked-in state is still there.
5. **Clock Out** — the same row is closed, not deleted.
6. Open **Team Chat**, send a message, and (from a second device/tab
   signed in as a different member of the same event) watch it arrive
   without a refresh.

## Engineering decisions

- **Server-backed attendance state.** `time_entries` is the only source
  of truth for "am I clocked in"; the UI never keeps its own boolean.
  The visible elapsed-time counter is a local `Timer` that recomputes a
  display value from the persisted `clock_in` every second — it doesn't
  store or invent attendance state.
- **`timestamptz` everywhere.** Every timestamp column is `timestamptz`,
  so ordering and comparisons (`ends_at > now()`, `clock_out >=
  clock_in`) are correct regardless of client time zone; Dart converts
  to local time only at render time.
- **RLS as the actual authorization boundary.** Every table has RLS
  enabled with explicit policies (see the migration). Notably,
  `time_entries` INSERT and `messages` INSERT/SELECT policies check
  event membership via a subquery on `event_members` — a user cannot
  clock into or chat in an event they haven't joined, even if the
  client were compromised or skipped its own checks entirely.
- **Partial unique index for active attendance.**
  `one_active_time_entry_per_user_event` is a unique index on
  `(user_id, event_id) WHERE clock_out IS NULL`. It's the one thing
  that actually prevents a double clock-in under concurrent requests;
  the repository just catches the resulting `23505` and shows a
  friendly message.
- **Scoped, disposed realtime subscriptions.** `ChatController` is an
  `AsyncNotifierProvider.autoDispose.family`, keyed by `eventId`. It
  opens one Postgres-changes channel filtered to that event's messages
  and, in `ref.onDispose`, calls `removeChannel`. Leaving the chat
  screen drops the last watcher, which disposes the provider, which
  tears down the channel — there's no code path that leaks a
  subscription or keeps a global "all events" listener open.
- **Latest-50 chat query.** History is fetched with
  `.order('created_at', ascending: false).limit(50)` and reversed for
  display, rather than loading the full thread.
- **No optimistic local chat append.** Sending a message inserts a row
  and returns; the message reaches the sender's own screen through the
  same realtime INSERT path as everyone else's. One source of truth,
  and no risk of a duplicated or out-of-order local echo.
- **Friendly errors only.** Every repository method catches
  Supabase/Postgrest/Auth exceptions and throws `AppFailure` with a
  short, user-safe message (`core/error/`); raw exception text never
  reaches a `SnackBar` or screen.

## Known limitations

- No sign-up flow — users are created directly in Supabase for the
  demo, matching the "demo credentials documented after a hosted
  project exists" note in the design brief.
- Chat shows "you" vs. other members by user id only (no display name),
  because the `profiles` RLS policy in scope only allows reading your
  *own* profile. Broadening it to "read profiles of people you share an
  event with" would be a natural next step, but was left out to keep
  the authorization surface exactly as specified.
- The "join" button shows its spinner per-card via a small UI-only
  provider (`joiningEventIdProvider`); if you tap join on a card and
  immediately background/foreground the app, that transient UI state
  (not the join itself) resets — the actual membership is unaffected
  since it's read back from `event_members`.
- "Upcoming" events are simply "events that haven't ended yet" — there's
  no separate past-events view, calendar, or filtering, per the
  non-goals in the design brief.
- Only `web/` platform scaffolding is included; run `flutter create .`
  if you want native `android/`/`ios/` folders for device builds.

## Testing

```bash
flutter test
```

- `test/error_mapper_test.dart` — duplicate-row (`23505`) mapping used
  by both "join twice" and "clock in twice".
- `test/time_entry_model_test.dart` — active/inactive attendance mapping
  and the clock-in → clock-out transition.
- `test/event_model_test.dart`, `test/chat_message_model_test.dart` —
  row-parsing for the two other models.
- `test/widget/sign_in_screen_test.dart` — login validation (empty
  fields, invalid email format).
- `test/widget/event_list_screen_test.dart` — empty state, and
  `Available`/`Join Shift` vs. `Confirmed`/`View Shift` rendering, via
  provider overrides (no live Supabase project needed to run these).
- `test/widget/attendance_panel_test.dart` — `Clock In` vs. `Clock Out`
  button/badge state, via provider overrides.

## Validation

This repo was written in an environment without the Flutter/Dart SDK or
network access, so `flutter pub get`, `flutter analyze`, `flutter test`,
and `flutter build web` could not be executed as part of building it.
Run them locally after `flutter pub get`:

```bash
flutter format .
flutter analyze
flutter test
flutter build web \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If a dependency version in `pubspec.yaml` doesn't resolve against your
installed Flutter SDK, bump that one line — the code doesn't rely on
anything exotic from any of them.
