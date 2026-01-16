-- Add email column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Populate email for all existing users
UPDATE profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id AND p.email IS NULL;

-- Create index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
