-- EventCrew security hardening
-- Remove anonymous/public EXECUTE grants from SECURITY DEFINER functions.

revoke all on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.handle_new_user() to service_role;

revoke all on function public.list_upcoming_events() from public, anon;
grant execute on function public.list_upcoming_events() to authenticated, service_role;

revoke all on function public.get_event_staffing(uuid) from public, anon;
grant execute on function public.get_event_staffing(uuid) to authenticated, service_role;

revoke all on function public.join_event(uuid) from public, anon;
grant execute on function public.join_event(uuid) to authenticated, service_role;

revoke all on function public.leave_event(uuid) from public, anon;
grant execute on function public.leave_event(uuid) to authenticated, service_role;
