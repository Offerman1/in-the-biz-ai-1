# FIX: Row-Level Security Error for Jobs Table

## Error:
```
Error saving job postgres exception message. New row violates row level security policy for table jobs code 42501
```

## Solution:
Run this SQL in your Supabase Dashboard → SQL Editor:

### Quick Fix (Copy and paste this):
```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can insert own jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can update own jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can delete own jobs" ON public.jobs;

-- Recreate policies with proper permissions
CREATE POLICY "Users can view own jobs" ON public.jobs
    FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own jobs" ON public.jobs
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own jobs" ON public.jobs
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own jobs" ON public.jobs
    FOR DELETE 
    USING (auth.uid() = user_id);
```

### Steps:
1. Go to: https://supabase.com/dashboard/project/bokdjidrybwxbomemmrg/sql/new
2. Paste the SQL above
3. Click "Run"
4. Try saving a job again in the app

### What This Does:
- Drops and recreates the Row-Level Security (RLS) policies for the `jobs` table
- Ensures authenticated users can insert/update/delete their own jobs
- The `WITH CHECK` clause validates the user_id matches the authenticated user

### Alternative: Use Supabase CLI
If you have the Supabase CLI installed:
```bash
cd "c:\Users\Brandon 2021\Desktop\In The Biz AI"
supabase db push
```

This will apply the migration file: `supabase/migrations/20251226000001_fix_jobs_rls.sql`
