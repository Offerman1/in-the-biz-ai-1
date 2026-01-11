-- ============================================================================
-- Enhanced BEO System - Comprehensive Event Management
-- Created: January 11, 2026
-- Purpose: Full BEO lifecycle support with all industry-standard fields
-- ============================================================================

-- ============================================================================
-- 1. ADD NEW COLUMNS TO BEO_EVENTS TABLE
-- ============================================================================

-- Post As / Display Name
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS post_as TEXT; -- How event appears on signage

-- Account/Organization
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS account_name TEXT; -- Corporate account name

-- Internal Contacts
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS sales_manager_name TEXT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS sales_manager_phone TEXT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS sales_manager_email TEXT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS catering_manager_name TEXT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS catering_manager_phone TEXT;

-- Timeline & Logistics
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS setup_date DATE;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS teardown_date DATE;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS load_in_time TIME;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS guest_arrival_time TIME;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS load_out_time TIME;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS function_space TEXT; -- Room/area name (Crystal Ballroom, etc.)

-- Detailed Guest Counts
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS adult_count INT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS child_count INT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS vendor_meal_count INT;

-- Detailed Financials (Tier 1 structured fields)
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS food_total DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS beverage_total DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS labor_total DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS room_rental DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS equipment_rental DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS subtotal DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS service_charge_percent DECIMAL(5, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS service_charge_amount DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS tax_percent DECIMAL(5, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS gratuity_amount DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS grand_total DECIMAL(10, 2);
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS deposits_paid DECIMAL(10, 2);

-- Food & Beverage Details (Tier 2 JSON fields)
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS menu_style TEXT; -- Buffet, Plated, Stations, Family Style
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS menu_details JSONB; -- Full menu breakdown {"appetizers":[], "entrees":[], "desserts":[], etc.}
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS beverage_details JSONB; -- {"package":"Non-Alcoholic", "bar_type":"Open/Cash/Host", "drink_tickets":3, etc.}
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS dietary_restrictions TEXT; -- Allergies, special dietary needs

-- Room Setup & Inventory (Tier 2 JSON)
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS setup_details JSONB; -- {"tables":[], "chairs":[], "linens":{}, "decor":[], "av_equipment":[], etc.}
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS floor_plan_notes TEXT;

-- Staffing & Services (Tier 2 JSON)
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS staffing_details JSONB; -- {"servers":2, "bartenders":1, "security":0, "valet":false, etc.}
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS vendor_details JSONB; -- [{"name":"Jason Blank", "type":"DJ", "phone":"", "email":"", "notes":""}, etc.]

-- Timeline/Agenda (Tier 2 JSON)
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS event_timeline JSONB; -- [{"time":"5:00 PM", "activity":"Guest Arrival"}, {"time":"6:00 PM", "activity":"Dinner Service"}, etc.]

-- Billing & Legal
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS payment_method TEXT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS cancellation_policy TEXT;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS client_signature_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS venue_signature_date TIMESTAMP WITH TIME ZONE;

-- User customization (for PDF export)
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS is_standalone BOOLEAN DEFAULT FALSE; -- TRUE if not linked to shift
ALTER TABLE public.beo_events 
ADD COLUMN IF NOT EXISTS created_manually BOOLEAN DEFAULT FALSE; -- TRUE if user created, FALSE if scanned

-- ============================================================================
-- 2. ADD BEO_EVENT_ID TO SHIFTS TABLE
-- ============================================================================

ALTER TABLE public.shifts 
ADD COLUMN IF NOT EXISTS beo_event_id UUID REFERENCES public.beo_events(id) ON DELETE SET NULL;

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_shifts_beo_event_id ON public.shifts(beo_event_id);

-- ============================================================================
-- 3. ADD LOGO_URL TO PROFILES TABLE (for PDF export branding)
-- ============================================================================

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_logo_url TEXT;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_address TEXT;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_phone TEXT;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_email TEXT;
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_website TEXT;

-- ============================================================================
-- 4. ENSURE EVENT_CONTACTS TABLE SUPPORTS VENDORS
-- ============================================================================

-- Check if vendor_type column exists, if not add it
ALTER TABLE public.event_contacts 
ADD COLUMN IF NOT EXISTS vendor_type TEXT; -- DJ, Florist, Photographer, Caterer, etc.
ALTER TABLE public.event_contacts 
ADD COLUMN IF NOT EXISTS source_event_id UUID REFERENCES public.beo_events(id) ON DELETE SET NULL;
ALTER TABLE public.event_contacts 
ADD COLUMN IF NOT EXISTS source_event_name TEXT; -- For display purposes

-- ============================================================================
-- 5. CALENDAR VIEW (Skip - handle in application code)
-- ============================================================================
-- Note: Calendar events combining shifts + standalone BEOs will be handled in Dart
-- This avoids conflicts with any existing calendar_events objects

-- ============================================================================
-- 6. UPDATE FUNCTION FOR UPDATED_AT TRIGGER
-- ============================================================================

-- Make sure updated_at is set on updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS update_beo_events_updated_at ON public.beo_events;
CREATE TRIGGER update_beo_events_updated_at
    BEFORE UPDATE ON public.beo_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. ADD HELPFUL COMMENTS
-- ============================================================================

COMMENT ON COLUMN public.beo_events.menu_details IS 'JSON: {"appetizers":[{"name":"...", "qty":80, "price":5.00}], "entrees":[], "desserts":[], "sides":[]}';
COMMENT ON COLUMN public.beo_events.beverage_details IS 'JSON: {"package":"Non-Alcoholic", "price_per_person":5.00, "bar_type":"Open/Cash/Host", "drink_tickets":3, "cash_bar_after":true}';
COMMENT ON COLUMN public.beo_events.setup_details IS 'JSON: {"tables":[{"type":"60in round", "qty":8, "linen":"white"}], "chairs":{"qty":80, "type":"chiavari"}, "decor":["navy spandex high tops", "silver votives"], "av":["microphone", "projector"]}';
COMMENT ON COLUMN public.beo_events.staffing_details IS 'JSON: {"servers":4, "bartenders":2, "security":1, "valet":false, "av_tech":0, "captain":1}';
COMMENT ON COLUMN public.beo_events.vendor_details IS 'JSON: [{"name":"Jason Blank", "type":"DJ", "company":"DJ Entertainment", "phone":"555-1234", "email":"", "notes":""}]';
COMMENT ON COLUMN public.beo_events.event_timeline IS 'JSON: [{"time":"5:00 PM", "activity":"Guest Arrival"}, {"time":"5:30 PM", "activity":"Cocktail Hour"}, {"time":"6:30 PM", "activity":"Dinner Service"}]';

COMMENT ON COLUMN public.shifts.beo_event_id IS 'Links shift to a BEO event for comprehensive event tracking';
COMMENT ON COLUMN public.profiles.company_logo_url IS 'URL to company logo for PDF export branding';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
