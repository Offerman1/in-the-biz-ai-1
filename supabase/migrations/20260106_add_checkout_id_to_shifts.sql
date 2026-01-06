-- Add checkout_id to shifts table to link shifts with server checkouts
-- This creates a relationship between the raw checkout data and the shift record

ALTER TABLE shifts ADD COLUMN IF NOT EXISTS checkout_id UUID REFERENCES server_checkouts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_shifts_checkout_id ON shifts(checkout_id);

COMMENT ON COLUMN shifts.checkout_id IS 'Links this shift to a server checkout (optional)';
