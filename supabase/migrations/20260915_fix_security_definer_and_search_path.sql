-- Fix mutable search path and revoke unauthorized execute privileges on SECURITY DEFINER functions

-- 1. activate_team_when_full (trigger function)
ALTER FUNCTION public.activate_team_when_full() SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.activate_team_when_full() FROM PUBLIC, anon, authenticated;

-- 2. cleanup_expired_invite_codes (maintenance function)
ALTER FUNCTION public.cleanup_expired_invite_codes() SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_invite_codes() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_invite_codes() TO service_role;

-- 3. reset_daily_notification_counts (maintenance function)
ALTER FUNCTION public.reset_daily_notification_counts() SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.reset_daily_notification_counts() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_daily_notification_counts() TO service_role;

-- 4. update_updated_at_column (trigger function)
ALTER FUNCTION public.update_updated_at_column() SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.update_updated_at_column() FROM PUBLIC, anon;
