-- ============================================================================
-- Finance System Foundation - Invoices, Receipts, Paychecks, Currency
-- Created: January 5, 2026
-- Purpose: Support full financial tracking for freelancers and W-2 workers
-- ============================================================================

-- 1. CREATE RECEIPTS TABLE
CREATE TABLE IF NOT EXISTS public.receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL, -- Link to shift
  
  -- Receipt Identity
  receipt_date DATE NOT NULL,
  vendor_name TEXT NOT NULL,
  receipt_number TEXT,
  
  -- Financials
  subtotal DECIMAL(10, 2),
  tax_amount DECIMAL(10, 2),
  total_amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'USD', -- Multi-currency support
  payment_method TEXT, -- 'Cash', 'Credit', 'Debit', 'Check', 'Other'
  
  -- Expense Categorization
  expense_category TEXT, -- 'Materials', 'Equipment', 'Travel', 'Meals', 'Supplies', 'Marketing', 'Utilities', 'Other'
  quickbooks_category TEXT, -- AI-suggested QuickBooks expense category (Schedule C)
  is_tax_deductible BOOLEAN DEFAULT true,
  
  -- Line Items (detailed breakdown)
  line_items JSONB, -- [{"description": "Lumber", "amount": 45.00}, ...]
  
  -- QuickBooks Integration
  quickbooks_synced BOOLEAN DEFAULT false,
  quickbooks_expense_id TEXT,
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

-- Indexes for Receipts
CREATE INDEX idx_receipts_user_id ON public.receipts(user_id);
CREATE INDEX idx_receipts_shift_id ON public.receipts(shift_id);
CREATE INDEX idx_receipts_date ON public.receipts(receipt_date);
CREATE INDEX idx_receipts_category ON public.receipts(expense_category);

-- RLS Policies for Receipts
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own receipts"
  ON public.receipts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own receipts"
  ON public.receipts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own receipts"
  ON public.receipts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own receipts"
  ON public.receipts FOR DELETE
  USING (auth.uid() = user_id);

-- 2. UPDATE INVOICES TABLE
-- Add shift_id link and currency
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = 'shift_id') THEN
        ALTER TABLE public.invoices ADD COLUMN shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = 'currency') THEN
        ALTER TABLE public.invoices ADD COLUMN currency TEXT DEFAULT 'USD';
    END IF;
    
    -- Add index for shift_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'invoices' AND indexname = 'idx_invoices_shift_id') THEN
        CREATE INDEX idx_invoices_shift_id ON public.invoices(shift_id);
    END IF;
END $$;

-- 3. UPDATE SHIFTS TABLE
-- Add currency support
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'shifts' AND column_name = 'currency') THEN
        ALTER TABLE public.shifts ADD COLUMN currency TEXT DEFAULT 'USD';
    END IF;
END $$;

-- 4. UPDATE PAYCHECKS TABLE
-- Add currency support
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'paychecks' AND column_name = 'currency') THEN
        ALTER TABLE public.paychecks ADD COLUMN currency TEXT DEFAULT 'USD';
    END IF;
END $$;

-- 5. CREATE USER PREFERENCES TABLE (for Global Settings)
CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Localization
  default_currency TEXT DEFAULT 'USD',
  language_code TEXT DEFAULT 'en',
  
  -- Formatting
  date_format TEXT DEFAULT 'MM/dd/yyyy',
  time_format TEXT DEFAULT '12-hour', -- '12-hour' or '24-hour'
  number_format TEXT DEFAULT 'en_US',
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS Policies for User Preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own preferences" ON public.user_preferences;
CREATE POLICY "Users can view their own preferences"
  ON public.user_preferences FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own preferences" ON public.user_preferences;
CREATE POLICY "Users can insert their own preferences"
  ON public.user_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own preferences" ON public.user_preferences;
CREATE POLICY "Users can update their own preferences"
  ON public.user_preferences FOR UPDATE
  USING (auth.uid() = user_id);
