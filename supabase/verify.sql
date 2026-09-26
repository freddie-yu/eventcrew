-- EventCrew deployment verification.
-- Safe, read-only checks after applying migrations 001 -> 003.

select
  to_regclass('public.profiles') is not null as profiles_exists,
  to_regclass('public.events') is not null as events_exists,
  to_regclass('public.event_members') is not null as event_members_exists,
  to_regclass('public.time_entries') is not null as time_entries_exists,
  to_regclass('public.messages') is not null as messages_exists,
  to_regclass('public.device_tokens') is not null as device_tokens_exists,
  to_regclass('public.notifications') is not null as notifications_exists;

select
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'events'
      and column_name = 'capacity'
  ) as events_capacity_exists;

select
  p.proname,
  pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'join_event',
    'leave_event',
    'list_upcoming_events',
    'get_event_staffing'
  )
order by p.proname;

select
  tablename,
  policyname,
  cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles',
    'event_members',
    'time_entries',
    'messages',
    'device_tokens',
    'notifications'
  )
order by tablename, policyname;

select
  title,
  capacity,
  starts_at,
  ends_at
from public.events
where id in (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444'
)
order by starts_at;
