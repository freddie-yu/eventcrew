-- EventCrew initial schema
-- Tables, foreign keys, unique constraints, indexes, RLS policies, and
-- the auth-user -> profile bootstrap trigger described in design.md.
-- Idempotent where practical so it can be safely re-run.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  avatar_url text,
  role text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Auto-create a profile row whenever a new auth user signs up, so the
-- client never has to special-case a missing profile. security definer
-- lets this bypass RLS to write the very first row for that user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- events
-- ---------------------------------------------------------------------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  title text not null,
  description text,
  location text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  constraint events_time_order check (ends_at > starts_at)
);

alter table public.events enable row level security;

drop policy if exists "events_select_authenticated" on public.events;
create policy "events_select_authenticated"
  on public.events for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------
-- event_members
-- ---------------------------------------------------------------------
create table if not exists public.event_members (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'confirmed',
  joined_at timestamptz not null default now(),
  constraint event_members_unique unique (event_id, user_id)
);

create index if not exists event_members_user_event_idx
  on public.event_members (user_id, event_id);

alter table public.event_members enable row level security;

drop policy if exists "event_members_select_own" on public.event_members;
create policy "event_members_select_own"
  on public.event_members for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "event_members_insert_own" on public.event_members;
create policy "event_members_insert_own"
  on public.event_members for insert
  to authenticated
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- time_entries
-- ---------------------------------------------------------------------
create table if not exists public.time_entries (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  clock_in timestamptz not null default now(),
  clock_out timestamptz,
  created_at timestamptz not null default now(),
  constraint time_entries_order check (clock_out is null or clock_out >= clock_in)
);

-- Attendance timestamps are assigned by PostgreSQL. A client may only
-- close its own active entry; it cannot rewrite or reopen attendance.
create or replace function public.guard_time_entry()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.clock_in := now();
    new.clock_out := null;
    new.created_at := now();
  else
    if old.clock_out is not null
       or new.id is distinct from old.id
       or new.event_id is distinct from old.event_id
       or new.user_id is distinct from old.user_id
       or new.clock_in is distinct from old.clock_in
       or new.created_at is distinct from old.created_at then
      raise exception 'time entry cannot be changed';
    end if;
    new.clock_out := now();
  end if;
  return new;
end;
$$;

drop trigger if exists guard_time_entry on public.time_entries;
create trigger guard_time_entry
  before insert or update on public.time_entries
  for each row execute function public.guard_time_entry();

-- Core invariant: at most one *active* (not clocked out) time entry per
-- user/event. Enforced in the database, not just the client.
create unique index if not exists one_active_time_entry_per_user_event
  on public.time_entries (user_id, event_id)
  where clock_out is null;

create index if not exists time_entries_user_event_idx
  on public.time_entries (user_id, event_id);

alter table public.time_entries enable row level security;

drop policy if exists "time_entries_select_own" on public.time_entries;
create policy "time_entries_select_own"
  on public.time_entries for select
  to authenticated
  using (user_id = auth.uid());

-- Clocking in requires event membership. This mirrors the app-level rule
-- in design.md ("user must be a member of the event") as a hard database
-- check rather than trusting the client.
drop policy if exists "time_entries_insert_own_member" on public.time_entries;
create policy "time_entries_insert_own_member"
  on public.time_entries for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.event_members
      where event_members.event_id = time_entries.event_id
        and event_members.user_id = auth.uid()
    )
  );

drop policy if exists "time_entries_update_own" on public.time_entries;
create policy "time_entries_update_own"
  on public.time_entries for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- messages
-- ---------------------------------------------------------------------
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(btrim(body)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists messages_event_created_idx
  on public.messages (event_id, created_at desc);

alter table public.messages enable row level security;

drop policy if exists "messages_select_event_members" on public.messages;
create policy "messages_select_event_members"
  on public.messages for select
  to authenticated
  using (
    exists (
      select 1 from public.event_members
      where event_members.event_id = messages.event_id
        and event_members.user_id = auth.uid()
    )
  );

drop policy if exists "messages_insert_event_members" on public.messages;
create policy "messages_insert_event_members"
  on public.messages for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.event_members
      where event_members.event_id = messages.event_id
        and event_members.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- Realtime: only `messages` needs INSERT broadcasts for this MVP.
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
