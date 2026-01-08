-- Create feature_requests table to log all feature suggestions from users
-- This table stores feature requests submitted via the AI assistant

CREATE TABLE IF NOT EXISTS feature_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  idea TEXT NOT NULL,
  category TEXT DEFAULT 'new_feature',
  email_sent BOOLEAN DEFAULT false,
  error_message TEXT,
  status TEXT DEFAULT 'pending', -- pending, reviewed, planned, completed, declined
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_feature_requests_user_id ON feature_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_requests_status ON feature_requests(status);
CREATE INDEX IF NOT EXISTS idx_feature_requests_created_at ON feature_requests(created_at DESC);

-- Enable RLS
ALTER TABLE feature_requests ENABLE ROW LEVEL SECURITY;

-- Users can only see their own feature requests
CREATE POLICY "Users can view own feature requests"
  ON feature_requests FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own feature requests
CREATE POLICY "Users can submit feature requests"
  ON feature_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Service role can do everything (for edge functions)
CREATE POLICY "Service role full access"
  ON feature_requests
  USING (auth.role() = 'service_role');

-- Add comment for documentation
COMMENT ON TABLE feature_requests IS 'Stores feature requests and suggestions submitted by users via the AI assistant';
