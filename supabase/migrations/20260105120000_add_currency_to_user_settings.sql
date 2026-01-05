-- Migration: Add currency column to user_settings table
-- Created: 2026-01-05
-- Purpose: Store user's preferred currency for money display

-- First, ensure the user_settings table exists
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  has_completed_onboarding BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Add the currency column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'currency'
  ) THEN
    ALTER TABLE user_settings 
    ADD COLUMN currency TEXT DEFAULT 'USD';
  END IF;
END $$;

-- Create an index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);

-- Enable RLS (Row Level Security)
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings;

-- Create RLS policies
CREATE POLICY "Users can view their own settings" 
  ON user_settings 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" 
  ON user_settings 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" 
  ON user_settings 
  FOR UPDATE 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create a function to auto-create user_settings when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_settings (user_id, currency, has_completed_onboarding)
  VALUES (NEW.id, 'USD', FALSE)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created_settings ON auth.users;

-- Create trigger to auto-create settings for new users
CREATE TRIGGER on_auth_user_created_settings
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_settings();

-- Backfill existing users with default currency
INSERT INTO user_settings (user_id, currency, has_completed_onboarding)
SELECT 
  id, 
  'USD', 
  TRUE  -- Assume existing users have completed onboarding
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM user_settings)
ON CONFLICT (user_id) DO NOTHING;
