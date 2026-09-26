# EventCrew architecture

EventCrew is structured like an app a developer would inherit and extend,
rather than a greenfield portfolio screen.

## Runtime flow

```text
Flutter UI
  -> Riverpod providers/controllers
    -> feature repositories/services
      -> Supabase Auth
      -> PostgreSQL + Row Level Security
      -> Supabase Realtime
      -> Firebase Messaging

Trusted operations backend
  -> Supabase Edge Function
    -> FCM HTTP v1
    -> notifications audit table
```

## Feature boundaries

- `auth`: session lifecycle and sign-in.
- `events`: upcoming shifts, capacity, confirmed/waitlisted membership.
- `attendance`: authoritative clock-in/out state.
- `chat`: event-scoped realtime communication plus member identity.
- `notifications`: optional Firebase token lifecycle and foreground delivery.
- `core`: routing, environment configuration, Supabase DI, shared theme.
- `shared`: reusable async/error/empty/status UI.

## Server-side staffing invariants

The client is not trusted to assign staffing state.

- One membership per user/event: unique constraint.
- Capacity assignment: `join_event()` locks the event row before counting.
- Waitlist promotion: `leave_event()` promotes the oldest waiting row.
- One active clock-in per user/event: partial unique index.
- Attendance timestamps: PostgreSQL trigger-owned.
- Clock-in: confirmed event membership is required by the database workflow.
- Shift leave: rejected while an active clock-in exists.
- Chat: readable/writable only by event members.
- Staff identity: profile rows are visible only to the owner or shared-event peers.
- Message payload: non-empty and capped at 1000 characters.

## Why RPCs for capacity

A client-side "count then insert" can overbook when two users claim the last
place concurrently. `join_event()` serializes the decision on the event row,
then inserts either `confirmed` or `waitlisted` in the same server operation.

## Realtime chat identity

Historical messages select the associated profile in the initial query.
Realtime payloads contain only the inserted message row, so the repository
hydrates the sender profile and caches it by user id before emitting the
typed `ChatMessage` to Riverpod.

The channel remains event-scoped and is removed when the auto-disposed provider
leaves the screen.

## Push security boundary

Flutter may hold Firebase public client configuration and an FCM registration
token. It never holds a Firebase service account.

`PushNotificationService`:
- requests notification permission
- registers the current FCM token in Supabase
- tracks token refresh
- exposes foreground messages

`send-shift-notification` Edge Function:
- requires a server-side dispatch secret
- uses the Supabase service role to find target device tokens
- obtains an OAuth token from the Firebase service account
- sends through FCM HTTP v1
- writes a notification audit/inbox row

## Design-to-code bridge

The Figma file uses the same operational vocabulary and core tokens as
`AppTheme`: primary #2757F2, app background #F5F6FA, border #E5E7EB,
success #15803D, warning #B45309, danger #DC2626, and 8/12/16 radius tiers.

Reusable design components map to Flutter concerns:
- Shift Card -> `EventCard`
- Capacity -> `CapacityIndicator`
- Attendance Panel -> `AttendancePanel`
- Status Badge -> `StatusBadge`
- Chat Bubble / Staff Avatar -> chat presentation widgets

## Delivery checks

GitHub Actions runs static analysis, unit/widget tests, and a release Web build
for every pull request targeting `master`.
