-- EventCrew operational guardrails
-- Adds server-side lifecycle rules that protect staffing workflows even when
-- clients are stale, offline, or racing.

-- A user may only join an event that is still open.
drop policy if exists "event_members_insert_own" on public.event_members;
create policy "event_members_insert_own_open_event"
  on public.event_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.events
      where events.id = event_members.event_id
        and events.ends_at > now()
    )
  );

-- A user may leave their own shift only when they do not have an active
-- attendance entry for it. This prevents an orphaned clock-in.
drop policy if exists "event_members_delete_own_not_clocked_in"
  on public.event_members;
create policy "event_members_delete_own_not_clocked_in"
  on public.event_members for delete
  to authenticated
  using (
    user_id = auth.uid()
    and not exists (
      select 1
      from public.time_entries
      where time_entries.event_id = event_members.event_id
        and time_entries.user_id = auth.uid()
        and time_entries.clock_out is null
    )
  );

-- Keep chat payloads bounded. The app already rejects blank messages; the
-- database now enforces a practical maximum even if another client bypasses UI.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'messages_body_length'
      and conrelid = 'public.messages'::regclass
  ) then
    alter table public.messages
      add constraint messages_body_length
      check (char_length(body) <= 1000);
  end if;
end $$;
