-- Migration: Fix webhook trigger to use pg_net directly
-- The supabase_functions.http_request may not be available, so use net.http_post
-- Run with: node scripts/run-migration.mjs supabase/migrations/20260112000002_fix_signup_webhook.sql

-- Drop and recreate the function to use net.http_post directly
CREATE OR REPLACE FUNCTION public.notify_new_user_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net
AS $$
DECLARE
  edge_function_url TEXT := 'https://bokdjidrybwxbomemmrg.supabase.co/functions/v1/notify-new-user';
  request_id BIGINT;
BEGIN
  -- Use pg_net to make async HTTP POST to our Edge Function
  -- The Edge Function was deployed with --no-verify-jwt, so no auth header needed
  SELECT net.http_post(
    url := edge_function_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'profiles',
      'schema', 'public',
      'record', jsonb_build_object(
        'id', NEW.id,
        'full_name', NEW.full_name,
        'avatar_url', NEW.avatar_url,
        'email', NEW.email,
        'created_at', COALESCE(NEW.created_at, now())
      ),
      'old_record', null
    )
  ) INTO request_id;
  
  RAISE LOG 'notify_new_user_signup: Sent notification for user %, request_id: %', NEW.id, request_id;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't block the signup - user creation should never fail due to email notification
    RAISE WARNING 'notify_new_user_signup error for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Recreate the trigger (just to be safe)
DROP TRIGGER IF EXISTS on_new_profile_notify ON public.profiles;
CREATE TRIGGER on_new_profile_notify
  AFTER INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_user_signup();

-- Ensure permissions
GRANT USAGE ON SCHEMA net TO postgres, service_role;
GRANT EXECUTE ON FUNCTION public.notify_new_user_signup() TO postgres, service_role;

COMMENT ON FUNCTION public.notify_new_user_signup() IS 'Sends async HTTP POST to notify-new-user Edge Function when a new user signs up';
