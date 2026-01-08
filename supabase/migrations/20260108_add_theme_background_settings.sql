-- Migration: Add per-theme background settings
-- Date: January 8, 2026
-- Purpose: Store background/gradient settings per theme instead of globally

-- Add theme_background_settings column to store JSON map of theme -> settings
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS theme_background_settings JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.user_preferences.theme_background_settings IS 'JSON map storing background settings per theme: {themeName: {mode, customColor, gradientColor1, gradientColor2}}';
