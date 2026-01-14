-- ============================================================================
-- Create receipt-scans storage bucket (PRIVATE)
-- Created: January 14, 2026
-- Purpose: Fix missing bucket for receipt scanning feature
-- ============================================================================

-- Create the receipt-scans bucket (PRIVATE - not public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipt-scans',
  'receipt-scans',
  false,  -- PRIVATE bucket (only user can access their own files)
  10485760,  -- 10MB file size limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- RLS Policy: Users can upload to their own folder
CREATE POLICY "Users can upload receipt scans to own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'receipt-scans' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS Policy: Users can view their own receipt scans
CREATE POLICY "Users can view own receipt scans"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'receipt-scans'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS Policy: Users can update their own receipt scans
CREATE POLICY "Users can update own receipt scans"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'receipt-scans'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS Policy: Users can delete their own receipt scans
CREATE POLICY "Users can delete own receipt scans"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'receipt-scans'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
