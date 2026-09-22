-- Sample non-auth seed data for local development / demos.
-- Run after the migration.
--
-- This intentionally does NOT create auth users or rows in
-- event_members / time_entries / messages: those are user-owned and
-- protected by RLS, so they should be created by signing in through the
-- app as a real Supabase Auth user, not inserted directly with an
-- invented UUID.

insert into public.events (id, title, description, location, starts_at, ends_at)
values
  (
    '11111111-1111-1111-1111-111111111111',
    'Riverside Music Festival — Load In',
    'Stage and vendor load-in crew. Steel-toe boots required.',
    'Riverside Park, Austin, TX',
    now() + interval '2 days' + interval '8 hours',
    now() + interval '2 days' + interval '16 hours'
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'Downtown Marathon — Water Station 4',
    'Staff and restock the mile-14 water station.',
    'Congress Ave & 6th St, Austin, TX',
    now() + interval '5 days' + interval '6 hours',
    now() + interval '5 days' + interval '12 hours'
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    'Tech Conference — Registration Desk',
    'Badge check-in and attendee support for day one.',
    'Austin Convention Center, Hall 3',
    now() + interval '9 days' + interval '7 hours',
    now() + interval '9 days' + interval '15 hours'
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    'Stadium Concert — Merch Booth',
    'Sell and restock merchandise before and during the show.',
    'Moody Center, Austin, TX',
    now() + interval '12 days' + interval '17 hours',
    now() + interval '12 days' + interval '23 hours'
  )
on conflict (id) do nothing;

-- To try the full flow locally:
--   1. Create a user (Supabase Studio -> Authentication -> Add user, or
--      supabase.auth.signUp from the app if you add a sign-up flow).
--   2. Sign in through the app.
--   3. Join one of the seeded events, clock in/out, and send chat
--      messages. The event_members / time_entries / messages rows are
--      created by the app itself, under RLS, as that signed-in user —
--      not by this seed file.
