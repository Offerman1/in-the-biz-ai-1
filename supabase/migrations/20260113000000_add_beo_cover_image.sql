-- ============================================================================
-- Add Cover Image Support for BEO Events
-- Created: January 13, 2026
-- Purpose: Allow users to set a custom cover image for BEO events
-- ============================================================================

-- Add cover_image_url column to beo_events table
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

-- Comment for documentation
COMMENT ON COLUMN public.beo_events.cover_image_url IS 'Path to custom cover image in beo-scans storage bucket';

-- Note: Uses the existing 'beo-scans' storage bucket, no new bucket needed
