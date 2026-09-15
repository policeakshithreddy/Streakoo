-- 1. Track Last AI Notification Time (for Global 24h cooldown)
-- Changing table name from 'profiles' to 'user_profiles' as per SupabaseService
create table if not exists public.user_profiles (
  user_id uuid references auth.users not null primary key,
  username text,
  age int
);
alter table public.user_profiles enable row level security;

alter table public.user_profiles 
add column if not exists last_ai_notification_at timestamp with time zone;

-- 2. Track Daily Notification Count (for 2/day limit)
alter table public.user_profiles 
add column if not exists daily_notification_count int default 0;

-- 3. Create Daily Quotes Table
create table if not exists public.daily_quotes (
    id uuid default gen_random_uuid() primary key,
    content text not null,
    author text,
    used_on_date date unique, -- Ensure only one quote is assigned per date
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on quotes
alter table public.daily_quotes enable row level security;

-- Policy: Everyone can read quotes
create policy "Everyone can read daily quotes"
on public.daily_quotes for select
to authenticated, anon
using (true);

-- Policy: Only Service Role can insert quotes (AI)
create policy "Service Role can manage quotes"
on public.daily_quotes for all
to service_role
using (true);

-- 4. Function to reset daily counts (Schedule this to run daily at midnight)
create or replace function reset_daily_notification_counts()
returns void as $$
begin
  update public.user_profiles set daily_notification_count = 0;
end;
$$ language plpgsql security definer;

-- 5. Schedule Reset (Midnight UTC)
-- Check if pg_cron is enabled
create extension if not exists pg_cron;

select cron.schedule(
  'reset-notification-counts',
  '0 0 * * *', -- Midnight UTC
  $$ select reset_daily_notification_counts(); $$
);
