-- Migration: Add industry-specific fields to shifts table
-- Date: December 31, 2025
-- Purpose: Support all industries with proper tracking fields

-- =====================================================
-- RIDESHARE & DELIVERY FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS rides_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS deliveries_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS dead_miles DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS fuel_cost DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS tolls_parking DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS surge_multiplier DECIMAL(4, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS acceptance_rate DECIMAL(5, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS base_fare DECIMAL(10, 2);

-- =====================================================
-- MUSIC & ENTERTAINMENT FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS gig_type TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS setup_hours DECIMAL(4, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS performance_hours DECIMAL(4, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS breakdown_hours DECIMAL(4, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS equipment_used TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS equipment_rental_cost DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS crew_payment DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS merch_sales DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS audience_size INTEGER;

-- =====================================================
-- ARTIST & CRAFTS FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS pieces_created INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS pieces_sold INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS materials_cost DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS sale_price DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS venue_commission_percent DECIMAL(5, 2);

-- =====================================================
-- RETAIL/SALES FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS items_sold INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS transactions_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS upsells_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS upsells_amount DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS returns_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS returns_amount DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS shrink_amount DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS department TEXT;

-- =====================================================
-- SALON/SPA FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS service_type TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS services_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS product_sales DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS repeat_client_percent DECIMAL(5, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS chair_rental DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS new_clients_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS returning_clients_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS walkin_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS appointment_count INTEGER;

-- =====================================================
-- HOSPITALITY FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS room_type TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS rooms_cleaned INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS quality_score DECIMAL(3, 1);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS shift_type TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS room_upgrades INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS guests_checked_in INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS cars_parked INTEGER;

-- =====================================================
-- HEALTHCARE FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS patient_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS shift_differential DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS on_call_hours DECIMAL(4, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS procedures_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS specialization TEXT;

-- =====================================================
-- FITNESS FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS sessions_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS session_type TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS class_size INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS retention_rate DECIMAL(5, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS cancellations_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS package_sales DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS supplement_sales DECIMAL(10, 2);

-- =====================================================
-- CONSTRUCTION/TRADES FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS labor_cost DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS subcontractor_cost DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS square_footage DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS weather_delay_hours DECIMAL(4, 2);

-- =====================================================
-- FREELANCER FIELDS
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS revisions_count INTEGER;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS client_type TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS expenses DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS billable_hours DECIMAL(4, 2);

-- =====================================================
-- RESTAURANT FIELDS (additional)
-- =====================================================
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS table_section TEXT;
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS cash_sales DECIMAL(10, 2);
ALTER TABLE public.shifts ADD COLUMN IF NOT EXISTS card_sales DECIMAL(10, 2);

-- =====================================================
-- INDEXES for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_shifts_gig_type ON public.shifts(gig_type);
CREATE INDEX IF NOT EXISTS idx_shifts_service_type ON public.shifts(service_type);
CREATE INDEX IF NOT EXISTS idx_shifts_shift_type ON public.shifts(shift_type);
CREATE INDEX IF NOT EXISTS idx_shifts_session_type ON public.shifts(session_type);

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration complete: Added all industry-specific fields to shifts table';
END $$;
