-- Migration: Create signup_notifications table for tracking new user signup emails
-- Run with: node scripts/run-migration.mjs supabase/migrations/20260112000000_create_signup_notifications.sql

-- Create the table to log signup notification emails
CREATE TABLE IF NOT EXISTS public.signup_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_email TEXT,
  user_name TEXT,
  provider TEXT,
  email_sent BOOLEAN DEFAULT false,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_signup_notifications_user_id ON public.signup_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_signup_notifications_created_at ON public.signup_notifications(created_at DESC);

-- Enable RLS (admin only - regular users shouldn't see this)
ALTER TABLE public.signup_notifications ENABLE ROW LEVEL SECURITY;

-- Only service role can insert/select (for the edge function and admin dashboard)
-- No user-facing policies needed since this is admin-only data

COMMENT ON TABLE public.signup_notifications IS 'Tracks email notifications sent for new user signups';
