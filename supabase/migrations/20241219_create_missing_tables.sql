-- Migration: Create missing tables and fix relationships
-- Date: 2024-12-19

-- 1. Create user_levels table for level/XP tracking
CREATE TABLE IF NOT EXISTS public.user_levels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    total_xp INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies for user_levels
ALTER TABLE public.user_levels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own level" ON public.user_levels;
CREATE POLICY "Users can view own level"
ON public.user_levels FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own level" ON public.user_levels;
CREATE POLICY "Users can insert own level"
ON public.user_levels FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own level" ON public.user_levels;
CREATE POLICY "Users can update own level"
ON public.user_levels FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own level" ON public.user_levels;
CREATE POLICY "Users can delete own level"
ON public.user_levels FOR DELETE
USING (auth.uid() = user_id);

-- 2. Create health_challenges table for health coaching
CREATE TABLE IF NOT EXISTS public.health_challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    target_days INTEGER DEFAULT 7,
    completed_days INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    category TEXT,
    difficulty TEXT DEFAULT 'medium',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies for health_challenges
ALTER TABLE public.health_challenges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own challenges" ON public.health_challenges;
CREATE POLICY "Users can view own challenges"
ON public.health_challenges FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own challenges" ON public.health_challenges;
CREATE POLICY "Users can insert own challenges"
ON public.health_challenges FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own challenges" ON public.health_challenges;
CREATE POLICY "Users can update own challenges"
ON public.health_challenges FOR UPDATE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own challenges" ON public.health_challenges;
CREATE POLICY "Users can delete own challenges"
ON public.health_challenges FOR DELETE
USING (auth.uid() = user_id);

-- 3. Create user_profiles table if not exists (needed for accountability partner joins)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add RLS policies for user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all profiles" ON public.user_profiles;
CREATE POLICY "Users can view all profiles"
ON public.user_profiles FOR SELECT
USING (true);  -- Allow reading all profiles for partner lookup

DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile"
ON public.user_profiles FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
ON public.user_profiles FOR UPDATE
USING (auth.uid() = user_id);

-- 4. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_levels_user_id ON public.user_levels(user_id);
CREATE INDEX IF NOT EXISTS idx_health_challenges_user_id ON public.health_challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);

-- Note: Foreign key constraints between accountability_partners and user_profiles
-- are not added to allow flexibility (partners might not have profiles yet)
