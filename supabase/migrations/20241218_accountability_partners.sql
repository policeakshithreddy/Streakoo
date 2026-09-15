-- Streakoo v2.2.0 Database Migration
-- Accountability Partners Feature
-- Run this in your Supabase SQL Editor

-- ============================================
-- Partner Invite Codes
-- ============================================
CREATE TABLE IF NOT EXISTS public.partner_invite_codes (
  code TEXT PRIMARY KEY,
  creator_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  is_used BOOLEAN DEFAULT FALSE NOT NULL
);

-- Index for looking up codes by creator
CREATE INDEX IF NOT EXISTS idx_invite_codes_creator ON public.partner_invite_codes(creator_user_id);

-- RLS Policies
ALTER TABLE public.partner_invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create their own invite codes" ON public.partner_invite_codes
  FOR INSERT WITH CHECK (auth.uid() = creator_user_id);

CREATE POLICY "Users can view their own invite codes" ON public.partner_invite_codes
  FOR SELECT USING (auth.uid() = creator_user_id);

CREATE POLICY "Anyone can use a valid invite code" ON public.partner_invite_codes
  FOR SELECT USING (NOT is_used AND expires_at > NOW());

CREATE POLICY "Users can update their own codes" ON public.partner_invite_codes
  FOR UPDATE USING (auth.uid() = creator_user_id);


-- ============================================
-- Accountability Partners
-- ============================================
CREATE TABLE IF NOT EXISTS public.accountability_partners (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'active', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, partner_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_partners_user ON public.accountability_partners(user_id);
CREATE INDEX IF NOT EXISTS idx_partners_partner ON public.accountability_partners(partner_id);

-- RLS Policies
ALTER TABLE public.accountability_partners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own partnerships" ON public.accountability_partners
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = partner_id);

CREATE POLICY "Users can create partnerships" ON public.accountability_partners
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own partnerships" ON public.accountability_partners
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own partnerships" ON public.accountability_partners
  FOR DELETE USING (auth.uid() = user_id);


-- ============================================
-- Partner Nudges (Encouragement Messages)
-- ============================================
CREATE TABLE IF NOT EXISTS public.partner_nudges (
  id TEXT PRIMARY KEY,
  from_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  to_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  habit_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  is_read BOOLEAN DEFAULT FALSE NOT NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_nudges_to_user ON public.partner_nudges(to_user_id);
CREATE INDEX IF NOT EXISTS idx_nudges_from_user ON public.partner_nudges(from_user_id);
CREATE INDEX IF NOT EXISTS idx_nudges_unread ON public.partner_nudges(to_user_id, is_read) WHERE is_read = FALSE;

-- RLS Policies
ALTER TABLE public.partner_nudges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view nudges sent to them" ON public.partner_nudges
  FOR SELECT USING (auth.uid() = to_user_id);

CREATE POLICY "Users can view nudges they sent" ON public.partner_nudges
  FOR SELECT USING (auth.uid() = from_user_id);

CREATE POLICY "Users can send nudges" ON public.partner_nudges
  FOR INSERT WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Users can mark their nudges as read" ON public.partner_nudges
  FOR UPDATE USING (auth.uid() = to_user_id);


-- ============================================
-- Partner Habit Misses (For notifications)
-- ============================================
CREATE TABLE IF NOT EXISTS public.partner_habit_misses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  habit_name TEXT NOT NULL,
  habit_emoji TEXT,
  missed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  is_notified BOOLEAN DEFAULT FALSE NOT NULL
);

-- Index for finding recent misses
CREATE INDEX IF NOT EXISTS idx_habit_misses_partner ON public.partner_habit_misses(partner_id, missed_at DESC);

-- RLS Policies
ALTER TABLE public.partner_habit_misses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can log their own misses" ON public.partner_habit_misses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Partners can view misses" ON public.partner_habit_misses
  FOR SELECT USING (auth.uid() = partner_id);


-- ============================================
-- Function: Clean up expired invite codes
-- ============================================
CREATE OR REPLACE FUNCTION cleanup_expired_invite_codes()
RETURNS void AS $$
BEGIN
  DELETE FROM public.partner_invite_codes
  WHERE expires_at < NOW() AND is_used = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================
-- (Optional) Scheduled cleanup via pg_cron
-- Uncomment if you have pg_cron extension enabled
-- ============================================
-- SELECT cron.schedule('0 0 * * *', 'SELECT cleanup_expired_invite_codes()');


-- ============================================
-- Grant permissions to authenticated users
-- ============================================
GRANT ALL ON public.partner_invite_codes TO authenticated;
GRANT ALL ON public.accountability_partners TO authenticated;
GRANT ALL ON public.partner_nudges TO authenticated;
GRANT ALL ON public.partner_habit_misses TO authenticated;
