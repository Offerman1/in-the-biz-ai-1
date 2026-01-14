-- EMERGENCY PRIVACY FIX - Make public buckets private immediately
-- Run: node scripts/run-migration.mjs scripts/make-all-buckets-private.sql

-- Make shift-attachments private (contains BEO scans, business documents)
UPDATE storage.buckets 
SET public = false 
WHERE name = 'shift-attachments';

-- Make contact-images private (contains business cards, contact info)
UPDATE storage.buckets 
SET public = false 
WHERE name = 'contact-images';

-- Verify all buckets are now private
SELECT name, public, created_at FROM storage.buckets ORDER BY name;