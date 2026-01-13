-- Create storage bucket for scan images
-- This bucket stores optimized images from all scan types:
-- BEO, Paycheck, Invoice, Receipt, Business Card, Server Checkout

-- Create the bucket (public for easy access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'scan-images',
  'scan-images',
  true,
  5242880, -- 5MB max per file (should be plenty for optimized images)
  ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for scan-images bucket

-- Allow authenticated users to upload to their own folder
CREATE POLICY "Users can upload scan images to own folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'scan-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to read their own images
CREATE POLICY "Users can read own scan images"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'scan-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own images
CREATE POLICY "Users can delete own scan images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'scan-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access (for displaying images in the app)
CREATE POLICY "Public can read scan images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'scan-images');

-- Add image_urls column to paychecks table (if not exists)
-- Note: The column might be named 'image_url' (singular) - we'll use that
-- Already has: image_url TEXT

-- Ensure shifts table has checkout_image_urls for server checkout scans
-- The shift model already has imageUrl, we can repurpose it or add a new field

COMMENT ON COLUMN storage.buckets IS 'scan-images bucket stores all scanned document images with optimized compression';
