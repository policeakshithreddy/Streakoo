-- FCM Tokens Table for Server-Side Push Notifications
-- Run this in Supabase SQL Editor: https://app.supabase.com/project/_/sql

-- 1. Create the fcm_tokens table
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_type TEXT, -- 'android', 'ios', 'macos'
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, token)
);

-- 2. Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);

-- 3. Enable Row Level Security
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- 4. Policy: Users can only manage their own tokens
CREATE POLICY "Users can insert own tokens"
ON fcm_tokens FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens"
ON fcm_tokens FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tokens"
ON fcm_tokens FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can view own tokens"
ON fcm_tokens FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 5. Service role can read all tokens (for Edge Functions)
CREATE POLICY "Service role can read all tokens"
ON fcm_tokens FOR SELECT
TO service_role
USING (true);
