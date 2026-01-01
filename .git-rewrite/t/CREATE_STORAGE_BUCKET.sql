-- Run this in Supabase Dashboard > SQL Editor to create the storage bucket
-- Go to: https://supabase.com/dashboard/project/bokdjidrybwxbomemmrg/sql/new

-- Create storage bucket for contact images (profile photos & business cards)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'contact-images',
  'contact-images', 
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload their own contact images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can upload contact images'
  ) THEN
    CREATE POLICY "Users can upload contact images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'contact-images' AND
      (storage.foldername(name))[1] = auth.uid()::text
    );
  END IF;
END $$;

-- Allow public read access to contact images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Public read access for contact images'
  ) THEN
    CREATE POLICY "Public read access for contact images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'contact-images');
  END IF;
END $$;

-- Allow users to delete their own contact images
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Users can delete own contact images'
  ) THEN
    CREATE POLICY "Users can delete own contact images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
      bucket_id = 'contact-images' AND
      (storage.foldername(name))[1] = auth.uid()::text
    );
  END IF;
END $$;

-- Verify bucket was created
SELECT * FROM storage.buckets WHERE id = 'contact-images';
