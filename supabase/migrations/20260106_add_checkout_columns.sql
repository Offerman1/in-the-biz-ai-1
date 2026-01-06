-- Add new columns to server_checkouts table for enhanced checkout scanning
-- These columns support the improved AI scanner that extracts more detailed data

-- Section/area worked
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS section TEXT;

-- Sales breakdown
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS comps DECIMAL(10,2);
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS promos DECIMAL(10,2);

-- Tips breakdown (credit vs cash)
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS credit_card_tips DECIMAL(10,2);
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS cash_tips DECIMAL(10,2);
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS total_tips_before_tipshare DECIMAL(10,2);
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS tip_share DECIMAL(10,2);

-- Hours worked (if shown on checkout)
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS hours_worked DECIMAL(5,2);

-- Rename gross_tips to align with new naming (if it exists)
-- Keep the old column for backwards compatibility
ALTER TABLE server_checkouts ADD COLUMN IF NOT EXISTS gross_sales DECIMAL(10,2);
