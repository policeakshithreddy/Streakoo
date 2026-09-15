-- Enable the pg_cron and pg_net extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Schedule the Edge Function to run daily at 8:00 PM (20:00) IST
-- Indian Standard Time is UTC+5:30.
-- 8:00 PM IST = 2:30 PM UTC = 30 14 * * *

-- Safely unschedule existing jobs (ignore errors if they don't exist)
DO $$
BEGIN
  PERFORM cron.unschedule('streak-reminder-daily');
EXCEPTION WHEN OTHERS THEN
  -- Job didn't exist, that's fine
  NULL;
END $$;

DO $$
BEGIN
  PERFORM cron.unschedule('weekly-summary');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- Schedule daily streak reminder at 8:00 PM IST (14:30 UTC)
SELECT cron.schedule(
  'streak-reminder-daily',
  '30 14 * * *',
  $$
  SELECT
    net.http_post(
        url := 'https://lnvtmsbgtrseqexhasna.supabase.co/functions/v1/send-notifications',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('supabase.service_role_key', true)
        ),
        body := '{"type": "streak-risk"}'::jsonb
    ) AS request_id;
  $$
);

-- Schedule Weekly Summary (Sundays at 9:00 AM IST = 3:30 AM UTC)
SELECT cron.schedule(
  'weekly-summary',
  '30 3 * * 0',
  $$
  SELECT
    net.http_post(
        url := 'https://lnvtmsbgtrseqexhasna.supabase.co/functions/v1/send-notifications',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('supabase.service_role_key', true)
        ),
        body := '{"type": "weekly-summary"}'::jsonb
    ) AS request_id;
  $$
);
