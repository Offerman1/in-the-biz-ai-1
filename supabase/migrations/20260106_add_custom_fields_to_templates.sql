-- Add custom_fields JSON column to job_templates table
-- This stores user-added fields for each job template

ALTER TABLE job_templates ADD COLUMN IF NOT EXISTS custom_fields JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN job_templates.custom_fields IS 'Array of custom fields added by user: [{key, enabled, deductFromEarnings, order}]';
