-- Add habit_goal and focus_mode_duration columns to habits table for backup
-- Run this in your Supabase SQL Editor

ALTER TABLE public.habits 
ADD COLUMN IF NOT EXISTS habit_goal TEXT,
ADD COLUMN IF NOT EXISTS focus_mode_duration INTEGER;
