-- Migration: Create database webhook trigger for new user signup notifications
-- This trigger calls the notify-new-user Edge Function when a new profile is created
-- Run with: node scripts/run-migration.mjs supabase/migrations/20260112000001_create_signup_webhook_trigger.sql

-- First, ensure pg_net extension is enabled (it should be by default on Supabase)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create the webhook trigger function that calls our Edge Function
CREATE OR REPLACE FUNCTION public.notify_new_user_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
BEGIN
  -- Get the Edge Function URL (Supabase project URL + function name)
  -- Your project ref is bokdjidrybwxbomemmrg
  edge_function_url := 'https://bokdjidrybwxbomemmrg.supabase.co/functions/v1/notify-new-user';
  
  -- Get the service role key from Vault (if stored there) or use anon key
  -- For Edge Functions with --no-verify-jwt, we can use the anon key
  service_role_key := current_setting('app.settings.service_role_key', true);
  
  -- If service role key is not set, try to get it from supabase_functions schema
  IF service_role_key IS NULL OR service_role_key = '' THEN
    -- Fallback: Use the http_request from supabase_functions which handles auth automatically
    PERFORM supabase_functions.http_request(
      edge_function_url,
      'POST',
      '{"Content-Type": "application/json"}',
      jsonb_build_object(
        'type', 'INSERT',
        'table', 'profiles',
        'schema', 'public',
        'record', to_jsonb(NEW),
        'old_record', null
      )::text,
      '5000'  -- 5 second timeout
    );
  ELSE
    -- Use net.http_post with explicit auth header
    PERFORM net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'type', 'INSERT',
        'table', 'profiles',
        'schema', 'public',
        'record', to_jsonb(NEW),
        'old_record', null
      )
    );
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't block the signup
    RAISE WARNING 'notify_new_user_signup error: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create the trigger on the profiles table
-- This fires AFTER a new profile is inserted (which happens on user signup via handle_new_user)
DROP TRIGGER IF EXISTS on_new_profile_notify ON public.profiles;
CREATE TRIGGER on_new_profile_notify
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_user_signup();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.notify_new_user_signup() TO postgres, service_role;

COMMENT ON FUNCTION public.notify_new_user_signup() IS 'Sends email notification when a new user signs up';
COMMENT ON TRIGGER on_new_profile_notify ON public.profiles IS 'Triggers new user email notification on signup';
