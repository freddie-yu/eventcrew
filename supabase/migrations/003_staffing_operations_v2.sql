-- EventCrew staffing operations v2
-- Capacity/waitlist, staff identity visibility, notification inbox and device tokens.

alter table public.events
  add column if not exists capacity integer not null default 12
  check (capacity > 0);

alter table public.event_members
  drop constraint if exists event_members_status_check;

alter table public.event_members
  add constraint event_members_status_check
  check (status in ('confirmed', 'waitlisted'));

create index if not exists event_members_event_status_joined_idx
  on public.event_members (event_id, status, joined_at);

-- Membership mutations now go exclusively through the atomic RPCs below.
-- Remove legacy direct client policies so old/stale clients cannot bypass
-- capacity assignment or waitlist promotion.
drop policy if exists "event_members_insert_own" on public.event_members;
drop policy if exists "event_members_insert_own_open_event" on public.event_members;
drop policy if exists "event_members_delete_own_not_clocked_in" on public.event_members;

-- Only confirmed staff may clock in. Waitlisted membership is not attendance
-- eligibility even if a stale or malicious client calls time_entries directly.
drop policy if exists "time_entries_insert_own_member" on public.time_entries;
create policy "time_entries_insert_own_confirmed_member"
  on public.time_entries for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.event_members
      where event_members.event_id = time_entries.event_id
        and event_members.user_id = auth.uid()
        and event_members.status = 'confirmed'
    )
  );

-- Event members may see the profile identity of people who share at least one
-- event with them. This supports named team chat without exposing the global
-- staff directory.
drop policy if exists "profiles_select_shared_event" on public.profiles;
create policy "profiles_select_shared_event"
  on public.profiles for select
  to authenticated
  using (
    id = auth.uid()
    or exists (
      select 1
      from public.event_members mine
      join public.event_members theirs
        on theirs.event_id = mine.event_id
      where mine.user_id = auth.uid()
        and mine.status = 'confirmed'
        and theirs.user_id = profiles.id
        and theirs.status = 'confirmed'
    )
  );

-- Team chat is restricted to confirmed staff. Waitlisted users do not gain
-- operational chat access before promotion.
drop policy if exists "messages_select_event_members" on public.messages;
create policy "messages_select_confirmed_event_members"
  on public.messages for select
  to authenticated
  using (
    exists (
      select 1 from public.event_members
      where event_members.event_id = messages.event_id
        and event_members.user_id = auth.uid()
        and event_members.status = 'confirmed'
    )
  );

drop policy if exists "messages_insert_event_members" on public.messages;
create policy "messages_insert_confirmed_event_members"
  on public.messages for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.event_members
      where event_members.event_id = messages.event_id
        and event_members.user_id = auth.uid()
        and event_members.status = 'confirmed'
    )
  );

-- Summary RPC exposes aggregate staffing counts without exposing other
-- users' membership rows.
create or replace function public.list_upcoming_events()
returns table (
  id uuid,
  created_at timestamptz,
  title text,
  description text,
  location text,
  starts_at timestamptz,
  ends_at timestamptz,
  capacity integer,
  confirmed_count bigint,
  waitlisted_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    e.id,
    e.created_at,
    e.title,
    e.description,
    e.location,
    e.starts_at,
    e.ends_at,
    e.capacity,
    count(em.id) filter (where em.status = 'confirmed') as confirmed_count,
    count(em.id) filter (where em.status = 'waitlisted') as waitlisted_count
  from public.events e
  left join public.event_members em on em.event_id = e.id
  where auth.uid() is not null
    and e.ends_at >= now()
  group by e.id
  order by e.starts_at;
$$;

revoke all on function public.list_upcoming_events() from public;
grant execute on function public.list_upcoming_events() to authenticated;

create or replace function public.get_event_staffing(p_event_id uuid)
returns table (
  capacity integer,
  confirmed_count bigint,
  waitlisted_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    e.capacity,
    count(em.id) filter (where em.status = 'confirmed') as confirmed_count,
    count(em.id) filter (where em.status = 'waitlisted') as waitlisted_count
  from public.events e
  left join public.event_members em on em.event_id = e.id
  where auth.uid() is not null
    and e.id = p_event_id
  group by e.id;
$$;

revoke all on function public.get_event_staffing(uuid) from public;
grant execute on function public.get_event_staffing(uuid) to authenticated;

-- Joining is serialized per event by locking the event row. This prevents two
-- concurrent clients from both claiming the final confirmed spot.
create or replace function public.join_event(p_event_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_capacity integer;
  v_ends_at timestamptz;
  v_confirmed integer;
  v_status text;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select e.capacity, e.ends_at
    into v_capacity, v_ends_at
  from public.events e
  where e.id = p_event_id
  for update;

  if not found then
    raise exception 'event not found';
  end if;

  if v_ends_at <= now() then
    raise exception 'event has ended';
  end if;

  select em.status into v_status
  from public.event_members em
  where em.event_id = p_event_id
    and em.user_id = v_user_id;

  if found then
    return v_status;
  end if;

  select count(*) into v_confirmed
  from public.event_members
  where event_id = p_event_id
    and status = 'confirmed';

  v_status := case when v_confirmed < v_capacity
    then 'confirmed'
    else 'waitlisted'
  end;

  insert into public.event_members (event_id, user_id, status)
  values (p_event_id, v_user_id, v_status);

  return v_status;
end;
$$;

revoke all on function public.join_event(uuid) from public;
grant execute on function public.join_event(uuid) to authenticated;

create or replace function public.leave_event(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_old_status text;
  v_promote_id uuid;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  perform 1 from public.events where id = p_event_id for update;

  if exists (
    select 1 from public.time_entries
    where event_id = p_event_id
      and user_id = v_user_id
      and clock_out is null
  ) then
    raise exception 'clock out before leaving shift';
  end if;

  delete from public.event_members
  where event_id = p_event_id
    and user_id = v_user_id
  returning status into v_old_status;

  if v_old_status = 'confirmed' then
    select id into v_promote_id
    from public.event_members
    where event_id = p_event_id
      and status = 'waitlisted'
    order by joined_at
    for update skip locked
    limit 1;

    if v_promote_id is not null then
      update public.event_members
      set status = 'confirmed'
      where id = v_promote_id;
    end if;
  end if;
end;
$$;

revoke all on function public.leave_event(uuid) from public;
grant execute on function public.leave_event(uuid) to authenticated;

-- Device tokens are owned by the signed-in user. Sending is handled by a
-- trusted backend / Edge Function using service credentials, never from Flutter.
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null,
  updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_own_all" on public.device_tokens;
create policy "device_tokens_own_all"
  on public.device_tokens for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
