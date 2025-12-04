-- Migration: Add missing columns for full data backup
-- Run this in the Supabase SQL Editor

-- 1. Add completion_dates as JSONB
ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS completion_dates JSONB DEFAULT '[]'::jsonb;

-- 2. Add Gamification fields
ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS xp_value INT DEFAULT 10;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS difficulty TEXT DEFAULT 'medium';

-- 3. Add Focus Task fields
ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS is_focus_task BOOLEAN DEFAULT false;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS focus_task_priority INT DEFAULT 0;

-- 4. Add Health Integration fields
ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS is_health_tracked BOOLEAN DEFAULT false;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS health_metric INT;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS health_goal_value DOUBLE PRECISION;

-- 5. Add Customization fields
ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS custom_color TEXT;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS custom_icon TEXT;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS reminder_time TEXT;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS reminder_enabled BOOLEAN DEFAULT false;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS frequency_days JSONB DEFAULT '[1,2,3,4,5,6,7]'::jsonb;

-- 6. Add Challenge fields
ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS challenge_target_days INT;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS challenge_progress INT DEFAULT 0;

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS challenge_completed BOOLEAN DEFAULT false;

-- Verify columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'habits';
