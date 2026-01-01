# Fix Daily Goals Error

## The Problem
The database constraint on the `goals` table doesn't include 'daily' as a valid type. It only allows:
- weekly
- monthly  
- yearly
- custom

This causes the error: **"PostgreSQL new row for goals violates check constraint goals_type_check code 23514"**

## The Solution
Run the migration file to add 'daily' to the allowed goal types.

## Steps to Fix

### Option 1: Run via Supabase Dashboard (Recommended)
1. Go to: https://supabase.com/dashboard/project/bokdjidrybwxbomemmrg/sql/new
2. Copy the contents of `supabase/migrations/20251226000001_add_daily_goal_type.sql`
3. Paste into the SQL editor
4. Click "Run"

### Option 2: Run via Supabase CLI
```bash
supabase db push
```

## What This Does
The migration will:
1. Drop the existing constraint that only allows ('weekly', 'monthly', 'yearly', 'custom')
2. Add a new constraint that includes 'daily': ('daily', 'weekly', 'monthly', 'yearly', 'custom')

## After Running
Once the migration is applied, you'll be able to create daily goals without errors!

## Migration SQL
```sql
-- Drop the existing constraint
ALTER TABLE public.goals DROP CONSTRAINT IF EXISTS goals_type_check;

-- Add the new constraint with 'daily' included
ALTER TABLE public.goals 
ADD CONSTRAINT goals_type_check 
CHECK (type IN ('daily', 'weekly', 'monthly', 'yearly', 'custom'));
```
