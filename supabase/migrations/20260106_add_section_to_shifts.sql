-- Add section field to shifts table
-- This tracks which section/area the server worked (Main Dining, Bar, Patio, etc.)

ALTER TABLE shifts ADD COLUMN IF NOT EXISTS section TEXT;

COMMENT ON COLUMN shifts.section IS 'Section or area worked during the shift (e.g., Main Dining, Bar, Patio, Section 1)';
