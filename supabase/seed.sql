-- Repeatable demo seed data.
-- Re-running this file refreshes event dates relative to "now" so the public
-- portfolio demo never ages into an empty-state-only experience.

insert into public.events (
  id,
  title,
  description,
  location,
  starts_at,
  ends_at,
  capacity
)
values
  (
    '11111111-1111-1111-1111-111111111111',
    'Riverside Music Festival — Load In',
    'Stage and vendor load-in crew. Steel-toe boots required.',
    'Riverside Park, Austin, TX',
    date_trunc('day', now()) + interval '2 days 8 hours',
    date_trunc('day', now()) + interval '2 days 16 hours',
    1
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'Downtown Marathon — Water Station 4',
    'Staff and restock the mile-14 water station.',
    'Congress Ave & 6th St, Austin, TX',
    date_trunc('day', now()) + interval '5 days 6 hours',
    date_trunc('day', now()) + interval '5 days 12 hours',
    4
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    'Tech Conference — Registration Desk',
    'Badge check-in and attendee support for day one.',
    'Austin Convention Center, Hall 3',
    date_trunc('day', now()) + interval '9 days 7 hours',
    date_trunc('day', now()) + interval '9 days 15 hours',
    8
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    'Stadium Concert — Merch Booth',
    'Sell and restock merchandise before and during the show.',
    'Moody Center, Austin, TX',
    date_trunc('day', now()) + interval '12 days 17 hours',
    date_trunc('day', now()) + interval '12 days 23 hours',
    12
  )
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  location = excluded.location,
  starts_at = excluded.starts_at,
  ends_at = excluded.ends_at,
  capacity = excluded.capacity;

-- Recommended demo setup:
--   demo.staff1@example.com  -> joins Riverside first -> Confirmed
--   demo.staff2@example.com  -> joins Riverside second -> Waitlisted
--
-- When staff1 leaves the event, leave_event() promotes staff2 automatically.
-- Create real Auth users through Supabase Authentication so profiles and RLS
-- are exercised exactly as they are in production.
