-- ============================================================================
-- AI Vision Scanner System - Complete Database Schema
-- Created: January 2, 2026
-- Purpose: Support BEO, Checkout, Paycheck, Business Card, and Invoice scanning
-- ============================================================================

-- ============================================================================
-- 1. BEO EVENTS TABLE (Event Planners)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.beo_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Event Identity
  event_name TEXT NOT NULL,
  event_date DATE NOT NULL,
  event_type TEXT, -- 'Wedding', 'Corporate', 'Birthday', 'Other'
  venue_name TEXT,
  venue_address TEXT,
  
  -- Logistics
  setup_time TIME,
  event_start_time TIME,
  event_end_time TIME,
  breakdown_time TIME,
  
  -- People
  guest_count_expected INT,
  guest_count_confirmed INT,
  primary_contact_name TEXT,
  primary_contact_phone TEXT,
  primary_contact_email TEXT,
  
  -- Financials
  total_sale_amount DECIMAL(10, 2),
  deposit_amount DECIMAL(10, 2),
  balance_due DECIMAL(10, 2),
  commission_percentage DECIMAL(5, 2),
  commission_amount DECIMAL(10, 2),
  
  -- Additional Details
  menu_items TEXT, -- Comma-separated or JSON
  decor_notes TEXT,
  staffing_requirements TEXT,
  special_requests TEXT,
  
  -- AI Metadata
  image_urls TEXT[], -- Array of uploaded image URLs (multi-page support)
  formatted_notes TEXT, -- AI-organized unstructured data
  ai_confidence_scores JSONB, -- {"event_name": 0.95, "guest_count": 0.78, ...}
  raw_ai_response JSONB, -- Full AI response for debugging
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for BEO Events
CREATE INDEX idx_beo_events_user_id ON public.beo_events(user_id);
CREATE INDEX idx_beo_events_event_date ON public.beo_events(event_date);
CREATE INDEX idx_beo_events_created_at ON public.beo_events(created_at);

-- RLS Policies for BEO Events
ALTER TABLE public.beo_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own BEO events"
  ON public.beo_events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own BEO events"
  ON public.beo_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own BEO events"
  ON public.beo_events FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own BEO events"
  ON public.beo_events FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 2. SERVER CHECKOUTS TABLE (Servers/Bartenders)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.server_checkouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL, -- Link to shift if applicable
  
  -- Checkout Identity
  checkout_date DATE NOT NULL,
  server_name TEXT,
  
  -- Financials
  total_sales DECIMAL(10, 2),
  net_sales DECIMAL(10, 2),
  gross_tips DECIMAL(10, 2),
  tipout_amount DECIMAL(10, 2),
  tipout_percentage DECIMAL(5, 2),
  net_tips DECIMAL(10, 2), -- Take home (Gross Tips - Tipout)
  
  -- Context
  table_count INT,
  cover_count INT,
  
  -- POS System
  pos_system TEXT, -- 'Toast', 'Square', 'Aloha', 'Clover', 'TouchBistro', 'Lightspeed', 'Handwritten', 'Other'
  pos_system_confidence DECIMAL(3, 2), -- AI confidence in POS detection
  
  -- Validation
  math_validated BOOLEAN DEFAULT false, -- True if Net Tips = Gross Tips - Tipout
  validation_notes TEXT, -- Any discrepancies found
  
  -- AI Metadata
  image_urls TEXT[], -- Array of images (for long multi-page receipts)
  ai_confidence_scores JSONB, -- {"total_sales": 0.98, "tips": 0.92, ...}
  raw_ai_response JSONB,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for Server Checkouts
CREATE INDEX idx_server_checkouts_user_id ON public.server_checkouts(user_id);
CREATE INDEX idx_server_checkouts_shift_id ON public.server_checkouts(shift_id);
CREATE INDEX idx_server_checkouts_date ON public.server_checkouts(checkout_date);
CREATE INDEX idx_server_checkouts_created_at ON public.server_checkouts(created_at);

-- RLS Policies for Server Checkouts
ALTER TABLE public.server_checkouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own server checkouts"
  ON public.server_checkouts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own server checkouts"
  ON public.server_checkouts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own server checkouts"
  ON public.server_checkouts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own server checkouts"
  ON public.server_checkouts FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 3. PAYCHECKS TABLE (W-2 Workers)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.paychecks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Pay Period
  pay_period_start DATE NOT NULL,
  pay_period_end DATE NOT NULL,
  pay_date DATE,
  
  -- Earnings
  gross_pay DECIMAL(10, 2),
  regular_hours DECIMAL(5, 2),
  overtime_hours DECIMAL(5, 2),
  hourly_rate DECIMAL(10, 2),
  overtime_rate DECIMAL(10, 2),
  
  -- Taxes & Deductions
  federal_tax DECIMAL(10, 2),
  state_tax DECIMAL(10, 2),
  fica_tax DECIMAL(10, 2),
  medicare_tax DECIMAL(10, 2),
  other_deductions DECIMAL(10, 2),
  other_deductions_description TEXT,
  
  -- Net Pay
  net_pay DECIMAL(10, 2),
  
  -- Year-to-Date Totals (CRITICAL for tax estimation)
  ytd_gross DECIMAL(10, 2),
  ytd_federal_tax DECIMAL(10, 2),
  ytd_state_tax DECIMAL(10, 2),
  ytd_fica DECIMAL(10, 2),
  ytd_medicare DECIMAL(10, 2),
  
  -- Pay Stub Format
  payroll_provider TEXT, -- 'ADP', 'Gusto', 'Paychex', 'QuickBooks', 'Generic', 'Other'
  employer_name TEXT,
  
  -- AI Metadata
  image_url TEXT, -- Single image (most pay stubs are 1 page)
  ai_confidence_scores JSONB,
  raw_ai_response JSONB,
  
  -- Reality Check Metadata
  reality_check_run BOOLEAN DEFAULT false,
  app_tracked_income DECIMAL(10, 2), -- Sum of shifts in this pay period
  w2_reported_income DECIMAL(10, 2), -- Gross pay from this stub
  unreported_gap DECIMAL(10, 2), -- Difference (for tax warnings)
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for Paychecks
CREATE INDEX idx_paychecks_user_id ON public.paychecks(user_id);
CREATE INDEX idx_paychecks_pay_period ON public.paychecks(pay_period_start, pay_period_end);
CREATE INDEX idx_paychecks_created_at ON public.paychecks(created_at);

-- RLS Policies for Paychecks
ALTER TABLE public.paychecks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own paychecks"
  ON public.paychecks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own paychecks"
  ON public.paychecks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own paychecks"
  ON public.paychecks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own paychecks"
  ON public.paychecks FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 4. INVOICES TABLE (Freelancers/1099 Contractors)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Invoice Identity
  invoice_number TEXT,
  invoice_date DATE NOT NULL,
  due_date DATE,
  
  -- Client Information
  client_name TEXT NOT NULL,
  client_email TEXT,
  client_phone TEXT,
  client_address TEXT,
  
  -- Financials
  subtotal DECIMAL(10, 2),
  tax_amount DECIMAL(10, 2),
  total_amount DECIMAL(10, 2) NOT NULL,
  amount_paid DECIMAL(10, 2) DEFAULT 0,
  balance_due DECIMAL(10, 2),
  
  -- Terms
  payment_terms TEXT, -- 'Net 30', 'Due on Receipt', 'Net 15', etc.
  
  -- Line Items (for detailed invoices)
  line_items JSONB, -- [{"description": "Design Services", "quantity": 10, "rate": 50, "amount": 500}, ...]
  
  -- Status
  status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'overdue', 'cancelled'
  paid_date DATE,
  
  -- QuickBooks Integration
  quickbooks_synced BOOLEAN DEFAULT false,
  quickbooks_invoice_id TEXT,
  quickbooks_category TEXT, -- Suggested income category
  quickbooks_sync_date TIMESTAMP WITH TIME ZONE,
  quickbooks_sync_error TEXT,
  
  -- AI Metadata
  image_urls TEXT[],
  ai_confidence_scores JSONB,
  raw_ai_response JSONB,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for Invoices
CREATE INDEX idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);
CREATE INDEX idx_invoices_due_date ON public.invoices(due_date);
CREATE INDEX idx_invoices_created_at ON public.invoices(created_at);

-- RLS Policies for Invoices
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own invoices"
  ON public.invoices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own invoices"
  ON public.invoices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own invoices"
  ON public.invoices FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own invoices"
  ON public.invoices FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 5. VISION SCAN ERRORS TABLE (Debugging & Improvement)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.vision_scan_errors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Nullable for privacy
  
  -- Error Context
  scan_type TEXT NOT NULL, -- 'beo', 'checkout', 'paycheck', 'business_card', 'invoice'
  error_type TEXT NOT NULL, -- 'ai_failed', 'low_confidence', 'user_reported', 'validation_failed'
  error_message TEXT,
  
  -- AI Response (for debugging)
  ai_response JSONB,
  image_count INT, -- How many images in this scan session
  
  -- User Feedback
  user_feedback TEXT, -- What the user said was wrong
  user_flagged BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for Vision Scan Errors
CREATE INDEX idx_vision_scan_errors_scan_type ON public.vision_scan_errors(scan_type);
CREATE INDEX idx_vision_scan_errors_error_type ON public.vision_scan_errors(error_type);
CREATE INDEX idx_vision_scan_errors_created_at ON public.vision_scan_errors(created_at);

-- RLS Policies for Vision Scan Errors (Admins only for privacy)
ALTER TABLE public.vision_scan_errors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Only admins can view scan errors"
  ON public.vision_scan_errors FOR SELECT
  USING (false); -- Disable for regular users, enable via service role

-- ============================================================================
-- 6. ENHANCE EVENT_CONTACTS TABLE (Business Card Scanner)
-- ============================================================================
-- Add social media fields to existing event_contacts table
ALTER TABLE public.event_contacts 
  ADD COLUMN IF NOT EXISTS instagram_handle TEXT,
  ADD COLUMN IF NOT EXISTS tiktok_handle TEXT,
  ADD COLUMN IF NOT EXISTS linkedin_url TEXT,
  ADD COLUMN IF NOT EXISTS twitter_handle TEXT,
  ADD COLUMN IF NOT EXISTS website TEXT,
  ADD COLUMN IF NOT EXISTS scanned_from_business_card BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS business_card_image_url TEXT,
  ADD COLUMN IF NOT EXISTS ai_confidence_scores JSONB;

-- ============================================================================
-- 7. STORAGE BUCKETS (Image Storage)
-- ============================================================================
-- Create storage buckets for all scan types
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('beo-scans', 'beo-scans', false),
  ('checkout-scans', 'checkout-scans', false),
  ('paycheck-scans', 'paycheck-scans', false),
  ('business-card-scans', 'business-card-scans', false),
  ('invoice-scans', 'invoice-scans', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies - Users can upload/view their own scans
CREATE POLICY "Users can upload their own BEO scans"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'beo-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own BEO scans"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'beo-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own checkout scans"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'checkout-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own checkout scans"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'checkout-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own paycheck scans"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'paycheck-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own paycheck scans"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'paycheck-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own business card scans"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'business-card-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own business card scans"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'business-card-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can upload their own invoice scans"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'invoice-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own invoice scans"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'invoice-scans' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================================
-- 8. UPDATED_AT TRIGGERS
-- ============================================================================
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables
CREATE TRIGGER update_beo_events_updated_at BEFORE UPDATE ON public.beo_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_server_checkouts_updated_at BEFORE UPDATE ON public.server_checkouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_paychecks_updated_at BEFORE UPDATE ON public.paychecks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- All database schemas for AI Vision Scanner System are now in place
-- Next steps: Build Edge Functions and UI components
