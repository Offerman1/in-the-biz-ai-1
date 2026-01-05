-- =====================================================
-- Add job end reason and notes columns
-- Run: node scripts/run-migration.mjs supabase/migrations/20260105150000_add_job_end_reason.sql
-- =====================================================

-- Add end_reason column (dropdown selection)
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS end_reason TEXT;

-- Add end_notes column (freeform notes from user)
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS end_notes TEXT;

-- Add ended_at timestamp to track when the job was ended
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ;

-- Add comment for documentation
COMMENT ON COLUMN jobs.end_reason IS 'Reason for ending job: promoted, better_opportunity, relocated, career_change, personal, terminated, mutual_agreement, contract_ended, quit_management, quit_burnout, laid_off, retired, other';
COMMENT ON COLUMN jobs.end_notes IS 'User freeform notes about why the job ended';
COMMENT ON COLUMN jobs.ended_at IS 'Timestamp when the job was marked as ended';
