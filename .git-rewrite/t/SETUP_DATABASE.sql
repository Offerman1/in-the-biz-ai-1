-- =====================================================
-- In The Biz AI - Database Setup
-- Run this in Supabase Dashboard → SQL Editor
-- https://supabase.com/dashboard/project/bokdjidrybwxbomemmrg/sql/new
-- =====================================================

-- Create shifts table
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    cash_tips DECIMAL(10,2) DEFAULT 0,
    credit_tips DECIMAL(10,2) DEFAULT 0,
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    hours_worked DECIMAL(5,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS shifts_user_id_idx ON public.shifts(user_id);
CREATE INDEX IF NOT EXISTS shifts_date_idx ON public.shifts(date);

-- Enable Row Level Security
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only see/modify their own shifts
CREATE POLICY "Users can view own shifts" ON public.shifts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own shifts" ON public.shifts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own shifts" ON public.shifts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own shifts" ON public.shifts
    FOR DELETE USING (auth.uid() = user_id);

-- Create shift_photos table for multiple images per shift
CREATE TABLE IF NOT EXISTS public.shift_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    photo_type TEXT DEFAULT 'gallery',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.shift_photos ENABLE ROW LEVEL SECURITY;

-- Policies for shift_photos
CREATE POLICY "Users can view own photos" ON public.shift_photos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own photos" ON public.shift_photos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos" ON public.shift_photos
    FOR DELETE USING (auth.uid() = user_id);

-- Create user profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    default_hourly_rate DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Function to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create storage bucket for shift photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('shift-photos', 'shift-photos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Users can upload own photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'shift-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own photos"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'shift-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'shift-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Create storage bucket for contact images (profile photos & business cards)
INSERT INTO storage.buckets (id, name, public)
VALUES ('contact-images', 'contact-images', true)
ON CONFLICT (id) DO NOTHING;

-- Contact images storage policies
CREATE POLICY "Users can upload contact images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'contact-images' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Public can view contact images"
ON storage.objects FOR SELECT
USING (bucket_id = 'contact-images');

CREATE POLICY "Users can delete own contact images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'contact-images' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);
