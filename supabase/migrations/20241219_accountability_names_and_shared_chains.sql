-- Add name columns to accountability_partners for better name visibility
-- Run this in your Supabase SQL Editor

-- Add columns to store names directly (avoids profile join issues)
ALTER TABLE public.accountability_partners 
ADD COLUMN IF NOT EXISTS initiator_name TEXT,
ADD COLUMN IF NOT EXISTS partner_name TEXT;

-- Optional: Create a table for shared chain challenges
CREATE TABLE IF NOT EXISTS public.shared_chain_challenges (
  id TEXT PRIMARY KEY,
  chain_name TEXT NOT NULL,
  chain_description TEXT,
  habit_ids TEXT[] NOT NULL, -- Array of habit names/descriptions
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- Track progress for each user
CREATE TABLE IF NOT EXISTS public.shared_chain_progress (
  id TEXT PRIMARY KEY,
  challenge_id TEXT REFERENCES public.shared_chain_challenges(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  completed_habit_indices INTEGER[] DEFAULT '{}' NOT NULL, -- Which habits they've completed today
  last_completed_at TIMESTAMP WITH TIME ZONE,
  streak_count INTEGER DEFAULT 0 NOT NULL,
  UNIQUE(challenge_id, user_id)
);

-- RLS Policies for shared_chain_challenges
ALTER TABLE public.shared_chain_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their challenges" ON public.shared_chain_challenges
  FOR SELECT USING (auth.uid() = created_by OR auth.uid() = partner_id);

CREATE POLICY "Users can create challenges" ON public.shared_chain_challenges
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creators can update challenges" ON public.shared_chain_challenges
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Creators can delete challenges" ON public.shared_chain_challenges
  FOR DELETE USING (auth.uid() = created_by);

-- RLS Policies for shared_chain_progress
ALTER TABLE public.shared_chain_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view progress" ON public.shared_chain_progress
  FOR SELECT USING (
    auth.uid() = user_id OR 
    auth.uid() IN (SELECT created_by FROM public.shared_chain_challenges WHERE id = challenge_id) OR
    auth.uid() IN (SELECT partner_id FROM public.shared_chain_challenges WHERE id = challenge_id)
  );

CREATE POLICY "Users can update own progress" ON public.shared_chain_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can modify own progress" ON public.shared_chain_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shared_challenges_creator ON public.shared_chain_challenges(created_by);
CREATE INDEX IF NOT EXISTS idx_shared_challenges_partner ON public.shared_chain_challenges(partner_id);
CREATE INDEX IF NOT EXISTS idx_shared_progress_challenge ON public.shared_chain_progress(challenge_id);
CREATE INDEX IF NOT EXISTS idx_shared_progress_user ON public.shared_chain_progress(user_id);
