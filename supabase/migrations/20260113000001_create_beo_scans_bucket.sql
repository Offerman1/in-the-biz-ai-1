-- ============================================================================
-- Create beo-scans storage bucket
-- Created: January 13, 2026
-- Purpose: Storage bucket for BEO scan images and cover images
-- ============================================================================

-- Create the beo-scans bucket (public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'beo-scans',
  'beo-scans',
  true,  -- public bucket
  52428800,  -- 50MB file size limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload BEO scans to own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'beo-scans' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own files
CREATE POLICY "Users can update own BEO scans"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'beo-scans'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own files
CREATE POLICY "Users can delete own BEO scans"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'beo-scans'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access (since bucket is public)
CREATE POLICY "Public read access for BEO scans"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'beo-scans');
