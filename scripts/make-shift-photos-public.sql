-- Make shift-attachments bucket public for web compatibility
-- Web has issues with signed URLs from private buckets
UPDATE storage.buckets 
SET public = true 
WHERE name = 'shift-attachments';

-- Verify the update
SELECT name, public FROM storage.buckets WHERE name = 'shift-attachments';