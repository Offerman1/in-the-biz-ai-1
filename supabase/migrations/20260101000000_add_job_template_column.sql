-- Add template column to jobs table for AI function calling
ALTER TABLE public.jobs ADD COLUMN template TEXT DEFAULT 'custom';

-- Add comment for clarity
COMMENT ON COLUMN public.jobs.template IS 'Job template type: restaurant, barbershop, events, rideshare, freelance, etc.';
