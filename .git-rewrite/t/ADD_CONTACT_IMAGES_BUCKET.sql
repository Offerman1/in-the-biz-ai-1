-- =====================================================
-- Add Contact Images Storage Bucket
-- Run this in Supabase Dashboard → SQL Editor
-- https://supabase.com/dashboard/project/bokdjidrybwxbomemmrg/sql/new
-- =====================================================

-- Create storage bucket for contact images (profile photos & business cards)
INSERT INTO storage.buckets (id, name, public)
VALUES ('contact-images', 'contact-images', true)
ON CONFLICT (id) DO NOTHING;

-- Contact images storage policies (with safety checks)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Users can upload contact images'
  ) THEN
    CREATE POLICY "Users can upload contact images"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'contact-images' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Public can view contact images'
  ) THEN
    CREATE POLICY "Public can view contact images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'contact-images');
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Users can delete own contact images'
  ) THEN
    CREATE POLICY "Users can delete own contact images"
    ON storage.objects FOR DELETE
    USING (
      bucket_id = 'contact-images' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;
END $$;

-- Verify bucket was created
SELECT id, name, public FROM storage.buckets WHERE id = 'contact-images';
