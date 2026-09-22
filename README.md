# EventCrew

A Flutter + Supabase staffing demo: **sign in → browse events → join a shift → clock in/out → team chat**.

Flutter · Supabase Auth · PostgreSQL/RLS · Realtime · Riverpod · go_router

Live demo and credentials: not configured yet. [Screenshot/GIF placeholder]

## What it shows

- Upcoming events and one-time shift signup
- Attendance restored from PostgreSQL after navigation or reload
- Event-only chat with the latest 50 messages and live inserts
- Loading, empty, and friendly error states

## Run locally

Requires Flutter 3.19+ and a Supabase project. This repo includes Web scaffolding; for Android/iOS, run `flutter create .` first.

1. In **Supabase → SQL Editor**, run `supabase/migrations/001_initial_schema.sql`, then `supabase/seed.sql`.
2. In **Authentication → Users**, add a demo user with an email and password. The migration creates its profile automatically.
3. From the repo root, run:

   ```bash
   flutter pub get
   flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

Find the project URL and anon key in **Supabase → Project Settings → API**. The anon key is public by design; RLS protects the data. Missing values show a setup message in the app.

## Deploy Web

1. Apply the SQL files and create a demo user as above.
2. Build with the same two `--dart-define` values:

   ```bash
   flutter build web --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

3. Upload **`build/web`** to any static host. Configure unknown paths to serve `index.html` so `/events/...` links work.

The migration enables Realtime for `messages`. If chat does not update live, check **Database → Replication** in Supabase.

## Demo flow

Sign in with the user you created. Join one of the four seeded shifts, clock in, reload to see attendance persist, clock out, and open Team Chat. For a live chat demo, create a second user and join the same shift in another tab or device.

## How it works

```text
Flutter screens → Riverpod providers → Supabase repositories
                                  → Auth / PostgreSQL + RLS / Realtime
```

Code is grouped by feature under `lib/features/`. PostgreSQL `timestamptz` values are rendered in local time. RLS limits user-owned rows and event chat to members. A unique membership constraint prevents duplicate joins; a partial unique index on `(user_id, event_id) WHERE clock_out IS NULL` prevents concurrent double clock-ins. Database triggers assign and protect attendance timestamps. Chat subscribes to INSERTs for one event, loads only the latest 50 messages, and removes its channel when the screen closes.

## Checks and limits

Run `flutter analyze`, `flutter test`, and `flutter build web` before publishing. The app has no signup or admin screen; demo users are created in Supabase. Chat shows your messages versus others, without member names. Native platform folders are not included.
