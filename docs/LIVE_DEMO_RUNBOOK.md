# EventCrew live demo runbook

This runbook turns the repository into a recruiter-facing demo backed by the
real Supabase project already used by the existing EventCrew web build.

## 1. Supabase target

Project URL:

```text
https://ryqwctcihrcbqllexuut.supabase.co
```

The Flutter web build uses the project's publishable client key. This is public
client configuration; authorization still comes from PostgreSQL Row Level
Security. Never place a service-role key in Flutter, GitHub, or a browser build.

Apply these files in order:

1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_operational_guardrails.sql`
3. `supabase/migrations/003_staffing_operations_v2.sql`
4. `supabase/seed.sql`
5. Run `supabase/verify.sql` and confirm all checks return the expected rows.

The seed is repeatable. Re-running it moves all four demo events back into the
future. The first event has capacity 1 specifically to make the waitlist flow
easy to demonstrate.

## 2. Demo users

Create two real Supabase Auth users rather than inserting fake profile UUIDs.

Suggested identities:

```text
demo.staff1@example.com  -> Alex Morgan  / Event Staff
demo.staff2@example.com  -> Sarah Jones  / Event Staff
```

After creation, update `profiles.full_name` and `profiles.role` if needed.

For the first seeded event:

1. Staff 1 joins first -> Confirmed.
2. Staff 2 joins second -> Waitlisted.
3. Staff 1 leaves -> Staff 2 is promoted automatically by `leave_event()`.

## 3. Edge Function

Deploy:

```text
supabase/functions/send-shift-notification
```

Required server-side secrets:

```text
FIREBASE_SERVICE_ACCOUNT
NOTIFICATION_DISPATCH_SECRET
```

Do not expose either value to Flutter or the public web build.

## 4. Firebase project

Create one Firebase project named something like `eventcrew-demo`, then add:

- Web app: EventCrew Web Demo
- Android app when native Android packaging is ready
- iOS app when native iOS packaging is ready

Enable Cloud Messaging. Copy only the public web/mobile Firebase client config
into build-time values. Keep the Firebase service-account JSON only in Supabase
Edge Function secrets.

Public build values expected by the app:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_AUTH_DOMAIN
FIREBASE_STORAGE_BUCKET
FIREBASE_VAPID_KEY
```

Push remains optional for the public web demo until these values are supplied.

## 5. Public web deployment

The repository contains `.github/workflows/deploy-web-demo.yml`.

One repository setting is required before the first deployment:

```text
GitHub -> eventcrew -> Settings -> Pages
Build and deployment -> Source -> GitHub Actions
```

Then run **Deploy Web Demo**, or push a web/app change to `master`.

Expected URL:

```text
https://freddie-yu.github.io/eventcrew/
```

The workflow builds the app against the same Supabase project used by the
existing EventCrew Vercel deployment.

## 6. Vercel

The existing production project is:

```text
eventcrew
alias: https://eventcrew-jade.vercel.app
```

It was originally deployed through the Vercel CLI. GitHub Pages is used as the
zero-secret repeatable public deployment path unless the Vercel project is later
connected to Git or supplied a Vercel deployment token.

## 7. 75-second recruiter demo

### 0-8s — Position the product

Screen: EventCrew logo / Upcoming Shifts.

Voice:

> EventCrew is a Flutter and Supabase staffing app focused on the workflows an
> event team actually needs: shift assignment, attendance, realtime chat and
> operational alerts.

### 8-22s — Capacity-aware staffing

Screen: Riverside event card, capacity meter, Staff 1 joins.

Voice:

> Shift capacity is enforced in PostgreSQL, not in Flutter. The first worker
> gets the confirmed place, and concurrent clients cannot overbook the final
> slot.

### 22-34s — Waitlist automation

Screen: Staff 2 joins the same full event and receives Waitlisted. Staff 1
leaves, then refresh Staff 2.

Voice:

> When the shift is full, the next worker enters a waitlist. If a confirmed
> worker leaves, the oldest waiting worker is promoted atomically on the server.

### 34-48s — Attendance integrity

Screen: Confirmed worker opens Shift Detail, clocks in, navigates away and
returns.

Voice:

> Clock-in timestamps are server-authoritative, and the active attendance state
> is restored from Postgres after navigation or reload.

### 48-62s — Realtime identity chat

Screen: Two browser sessions side by side. Send a message from Sarah.

Voice:

> Team chat is event-scoped and realtime. Messages include staff identity, while
> RLS prevents unrelated workers from browsing another event's team.

### 62-72s — Push architecture

Screen: briefly show notification architecture in README or a real push once
Firebase is enabled.

Voice:

> Device tokens are registered from Flutter, but Firebase service credentials
> stay in a trusted Supabase Edge Function using FCM HTTP v1.

### 72-78s — Close

Screen: GitHub Actions green + repository overview.

Voice:

> The project is tested in CI and structured as incremental work on an existing
> Flutter codebase, which is exactly how I would approach a production staffing
> app.

## Recording guidance

- Use desktop Chrome at about 390px mobile viewport for the main app.
- Keep a second incognito window ready for the second staff user.
- Pre-sign-in both users before recording.
- Do not spend recording time typing passwords or explaining setup.
- Keep cursor motion deliberate and cut network waits longer than roughly 0.5s.
- End on the GitHub repository rather than a generic title card so the reviewer
  can immediately verify the implementation.
