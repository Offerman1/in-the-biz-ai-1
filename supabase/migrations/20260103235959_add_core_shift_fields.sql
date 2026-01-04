-- Migration: Add core shift tracking fields
-- Date: January 3, 2026
-- Purpose: Add sales, tipout, scheduling, and calendar sync fields to shifts table

-- =====================================================
-- SALES & TIPOUT TRACKING FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS sales_amount DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS tipout_percent DECIMAL(5, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS additional_tipout DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS additional_tipout_note TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS event_cost DECIMAL(10, 2);

-- =====================================================
-- SHIFT STATUS & SOURCE FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'completed';
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';

-- =====================================================
-- RECURRING SHIFT FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS recurrence_rule TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS recurring_series_id TEXT;

-- =====================================================
-- CALENDAR SYNC FIELD
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS calendar_event_id TEXT;

-- =====================================================
-- INDEXES for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_shifts_status ON public.shifts(status);
CREATE INDEX IF NOT EXISTS idx_shifts_source ON public.shifts(source);
CREATE INDEX IF NOT EXISTS idx_shifts_recurring_series_id ON public.shifts(recurring_series_id);
CREATE INDEX IF NOT EXISTS idx_shifts_calendar_event_id ON public.shifts(calendar_event_id);
CREATE INDEX IF NOT EXISTS idx_shifts_is_recurring ON public.shifts(is_recurring) WHERE is_recurring = TRUE;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration complete: Added core shift tracking fields (sales, tipout, status, recurring, calendar sync)';
END $$;
