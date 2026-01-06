-- Add metadata columns to track how checkout data was interpreted
-- This allows users to correct AI assumptions about ambiguous fields

-- Track whether "table_count" represents tables or checks/payments
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS table_count_type TEXT;
COMMENT ON COLUMN server_checkouts.table_count_type IS 'Whether table_count represents "tables" or "checks" (payments)';

-- Track how cash_tips was determined
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS cash_tips_source TEXT;
COMMENT ON COLUMN server_checkouts.cash_tips_source IS 'How cash_tips was determined: "found" (on receipt), "calculated" (math), or "manual" (user entered)';

-- Track what label the AI saw on the receipt for table_count
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS table_count_label_found TEXT;
COMMENT ON COLUMN server_checkouts.table_count_label_found IS 'The actual label found on receipt (e.g., "CHECKS", "Tables", "Payments")';
