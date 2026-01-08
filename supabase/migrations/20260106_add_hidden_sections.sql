-- Migration: Add hidden sections support
-- Date: January 6, 2026
-- Purpose: Allow users to hide/show sections per job template or per shift

-- =====================================================
-- ADD HIDDEN_SECTIONS TO JOB_TEMPLATES
-- =====================================================
-- This stores which sections are hidden at the template level
-- Example: ['event_contract', 'notes', 'work_details']

-- Note: job_template is stored as JSONB in the jobs table
-- The hidden_sections field is added to the JobTemplate class
-- No database schema change needed since it's part of the JSONB

-- =====================================================
-- ADD SHIFT_HIDDEN_SECTIONS TO SHIFTS
-- =====================================================
-- This allows per-shift overrides for hidden sections

ALTER TABLE public.shifts 
ADD COLUMN IF NOT EXISTS shift_hidden_sections JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.shifts.shift_hidden_sections IS 'Array of section keys hidden for this specific shift (per-shift override)';

-- =====================================================
-- SECTION KEY REFERENCE
-- =====================================================
-- Available section keys:
--   'time_hours'        - Time & Hours section
--   'event_contract'    - Event Contract / BEO section
--   'work_details'      - Work Details (location, client, project)
--   'income_breakdown'  - Income Breakdown (tips, wages, rates)
--   'additional_earnings' - Additional Earnings (commission, flat rate, overtime)
--   'notes'             - Notes section
--   'attachments'       - Attachments/Photos section
--   'custom_fields'     - Custom Fields section
