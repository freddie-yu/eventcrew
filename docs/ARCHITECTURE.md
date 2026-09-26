# EventCrew architecture

EventCrew is deliberately structured like an app that a developer would inherit
and extend, rather than a one-screen portfolio prototype.

## Runtime flow

```text
Flutter UI
  -> Riverpod providers/controllers
    -> feature repositories
      -> Supabase Auth
      -> PostgreSQL + Row Level Security
      -> Supabase Realtime
```

## Feature boundaries

- `auth`: session lifecycle and sign-in.
- `events`: upcoming shifts, membership, join/leave lifecycle.
- `attendance`: authoritative clock-in/out state.
- `chat`: event-scoped realtime communication.
- `core`: routing, configuration, Supabase dependency injection, theme,
  user-safe error mapping.
- `shared`: reusable async/error/empty-state UI.

The repositories depend on an injected `SupabaseClient`. UI code never calls
`Supabase.instance.client` directly, keeping infrastructure concerns out of
screens and making providers replaceable in tests.

## Server-side invariants

The client is not trusted to enforce staffing rules.

- One membership per user/event: PostgreSQL unique constraint.
- One active clock-in per user/event: partial unique index.
- Attendance timestamps: written/protected by a PostgreSQL trigger.
- Clock-in: allowed only for an event member.
- Shift leave: rejected while an active clock-in exists.
- Event chat: readable/writable only by event members.
- Membership: users can only mutate their own records.
- Message payload: non-empty and capped at 1000 characters.

These rules matter when multiple devices race, network retries occur, or an old
client version sends stale state.

## Realtime lifecycle

Chat subscribes only to INSERTs for the selected event. The provider is
`autoDispose.family`, and its Supabase channel is removed when the screen is
disposed. Initial history and realtime inserts are de-duplicated by message id.

## Delivery checks

GitHub Actions runs formatting, static analysis, unit/widget tests, and a
release web build for every pull request targeting `master`.

## Deliberate scope

This repository is a focused staffing-app vertical slice, not an attempt to
rebuild an entire workforce-management platform. Production extensions are
listed in the README roadmap.
