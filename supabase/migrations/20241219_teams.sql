-- Streakoo Teams Feature Migration
-- Date: 2024-12-19
-- FIXED: Create all tables first, then add policies

-- =====================================================
-- STEP 1: CREATE ALL TABLES
-- =====================================================

-- TEAMS TABLE
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    creator_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    max_members INTEGER NOT NULL CHECK (max_members >= 2 AND max_members <= 4),
    status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'active', 'archived')),
    team_streak INTEGER DEFAULT 0,
    team_emoji TEXT DEFAULT '🔥',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TEAM MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role TEXT DEFAULT 'member' NOT NULL CHECK (role IN ('creator', 'member')),
    display_name TEXT,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

-- TEAM INVITE CODES TABLE
CREATE TABLE IF NOT EXISTS public.team_invite_codes (
    code TEXT PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    max_uses INTEGER NOT NULL,
    use_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TEAM HABITS TABLE
CREATE TABLE IF NOT EXISTS public.team_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    emoji TEXT DEFAULT '✅',
    description TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('proposed', 'active', 'completed', 'archived')),
    target_days INTEGER DEFAULT 7,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TEAM HABIT PROGRESS TABLE
CREATE TABLE IF NOT EXISTS public.team_habit_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_habit_id UUID REFERENCES public.team_habits(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    completed_date DATE NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_habit_id, user_id, completed_date)
);

-- TEAM REACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.team_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE NOT NULL,
    from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- =====================================================
-- STEP 2: CREATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_teams_creator ON public.teams(creator_id);
CREATE INDEX IF NOT EXISTS idx_teams_status ON public.teams(status);
CREATE INDEX IF NOT EXISTS idx_team_members_team ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_invite_team ON public.team_invite_codes(team_id);
CREATE INDEX IF NOT EXISTS idx_team_invite_creator ON public.team_invite_codes(created_by);
CREATE INDEX IF NOT EXISTS idx_team_habits_team ON public.team_habits(team_id);
CREATE INDEX IF NOT EXISTS idx_team_habits_status ON public.team_habits(status);
CREATE INDEX IF NOT EXISTS idx_team_progress_habit ON public.team_habit_progress(team_habit_id);
CREATE INDEX IF NOT EXISTS idx_team_progress_user ON public.team_habit_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_team_progress_date ON public.team_habit_progress(completed_date);
CREATE INDEX IF NOT EXISTS idx_team_reactions_team ON public.team_reactions(team_id);
CREATE INDEX IF NOT EXISTS idx_team_reactions_to ON public.team_reactions(to_user_id);


-- =====================================================
-- STEP 3: ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_habit_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_reactions ENABLE ROW LEVEL SECURITY;


-- =====================================================
-- STEP 4: CREATE ALL RLS POLICIES
-- =====================================================

-- TEAMS POLICIES
DROP POLICY IF EXISTS "Team members can view their teams" ON public.teams;
CREATE POLICY "Team members can view their teams" ON public.teams
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm 
        WHERE tm.team_id = id AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Creators can insert teams" ON public.teams;
CREATE POLICY "Creators can insert teams" ON public.teams
FOR INSERT WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can update teams" ON public.teams;
CREATE POLICY "Creators can update teams" ON public.teams
FOR UPDATE USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can delete teams" ON public.teams;
CREATE POLICY "Creators can delete teams" ON public.teams
FOR DELETE USING (auth.uid() = creator_id);


-- TEAM MEMBERS POLICIES
DROP POLICY IF EXISTS "Members can view team members" ON public.team_members;
CREATE POLICY "Members can view team members" ON public.team_members
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm 
        WHERE tm.team_id = team_id AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can join teams" ON public.team_members;
CREATE POLICY "Users can join teams" ON public.team_members
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own membership" ON public.team_members;
CREATE POLICY "Users can update own membership" ON public.team_members
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can leave teams" ON public.team_members;
CREATE POLICY "Users can leave teams" ON public.team_members
FOR DELETE USING (auth.uid() = user_id);


-- TEAM INVITE CODES POLICIES
DROP POLICY IF EXISTS "Creators can manage invite codes" ON public.team_invite_codes;
CREATE POLICY "Creators can manage invite codes" ON public.team_invite_codes
FOR ALL USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "Anyone can view valid codes" ON public.team_invite_codes;
CREATE POLICY "Anyone can view valid codes" ON public.team_invite_codes
FOR SELECT USING (expires_at > NOW() AND use_count < max_uses);


-- TEAM HABITS POLICIES
DROP POLICY IF EXISTS "Team members can view habits" ON public.team_habits;
CREATE POLICY "Team members can view habits" ON public.team_habits
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm 
        WHERE tm.team_id = team_id AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Team members can create habits" ON public.team_habits;
CREATE POLICY "Team members can create habits" ON public.team_habits
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.team_members tm 
        WHERE tm.team_id = team_id AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Habit creators can update" ON public.team_habits;
CREATE POLICY "Habit creators can update" ON public.team_habits
FOR UPDATE USING (auth.uid() = created_by);


-- TEAM HABIT PROGRESS POLICIES
DROP POLICY IF EXISTS "Team members can view progress" ON public.team_habit_progress;
CREATE POLICY "Team members can view progress" ON public.team_habit_progress
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.team_habits th
        JOIN public.team_members tm ON tm.team_id = th.team_id
        WHERE th.id = team_habit_id AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can log own progress" ON public.team_habit_progress;
CREATE POLICY "Users can log own progress" ON public.team_habit_progress
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own progress" ON public.team_habit_progress;
CREATE POLICY "Users can update own progress" ON public.team_habit_progress
FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own progress" ON public.team_habit_progress;
CREATE POLICY "Users can delete own progress" ON public.team_habit_progress
FOR DELETE USING (auth.uid() = user_id);


-- TEAM REACTIONS POLICIES
DROP POLICY IF EXISTS "Team members can view reactions" ON public.team_reactions;
CREATE POLICY "Team members can view reactions" ON public.team_reactions
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.team_members tm 
        WHERE tm.team_id = team_id AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Team members can send reactions" ON public.team_reactions;
CREATE POLICY "Team members can send reactions" ON public.team_reactions
FOR INSERT WITH CHECK (auth.uid() = from_user_id);


-- =====================================================
-- STEP 5: GRANTS
-- =====================================================

GRANT ALL ON public.teams TO authenticated;
GRANT ALL ON public.team_members TO authenticated;
GRANT ALL ON public.team_invite_codes TO authenticated;
GRANT ALL ON public.team_habits TO authenticated;
GRANT ALL ON public.team_habit_progress TO authenticated;
GRANT ALL ON public.team_reactions TO authenticated;


-- =====================================================
-- STEP 6: HELPER FUNCTION & TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION activate_team_when_full()
RETURNS TRIGGER AS $$
DECLARE
    member_count INTEGER;
    team_max INTEGER;
BEGIN
    SELECT COUNT(*) INTO member_count
    FROM public.team_members
    WHERE team_id = NEW.team_id;
    
    SELECT max_members INTO team_max
    FROM public.teams
    WHERE id = NEW.team_id;
    
    IF member_count >= team_max THEN
        UPDATE public.teams
        SET status = 'active', updated_at = NOW()
        WHERE id = NEW.team_id AND status = 'pending';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_activate_team ON public.team_members;
CREATE TRIGGER trigger_activate_team
    AFTER INSERT ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION activate_team_when_full();
