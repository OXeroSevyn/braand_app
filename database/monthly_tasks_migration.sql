-- Migration: Add date-specific task support to existing monthly_tasks table

-- Add new columns to monthly_tasks
ALTER TABLE public.monthly_tasks 
  ADD COLUMN IF NOT EXISTS task_type TEXT DEFAULT 'monthly',
  ADD COLUMN IF NOT EXISTS specific_date DATE,
  ADD COLUMN IF NOT EXISTS time_limit_hours INT,
  ADD COLUMN IF NOT EXISTS deadline_time TIMESTAMP WITH TIME ZONE;

-- Update the constraint (drop old if exists, add new)
DO $$ 
BEGIN
  -- Drop the old NOT NULL constraints on month/year if they exist
  ALTER TABLE public.monthly_tasks 
    ALTER COLUMN month DROP NOT NULL,
    ALTER COLUMN year DROP NOT NULL;
EXCEPTION 
  WHEN OTHERS THEN NULL;
END $$;

-- Add the task_type check constraint
DO $$
BEGIN
  ALTER TABLE public.monthly_tasks 
    ADD CONSTRAINT task_type_check CHECK (task_type IN ('monthly', 'daily'));
EXCEPTION 
  WHEN duplicate_object THEN NULL;
END $$;

-- Add the validation constraint
DO $$
BEGIN
  ALTER TABLE public.monthly_tasks 
    ADD CONSTRAINT task_type_validation CHECK (
      (task_type = 'monthly' AND month IS NOT NULL AND year IS NOT NULL AND specific_date IS NULL) OR
      (task_type = 'daily' AND specific_date IS NOT NULL AND month IS NULL AND year IS NULL)
    );
EXCEPTION 
  WHEN duplicate_object THEN NULL;
END $$;

-- Add started_at column to user_monthly_tasks
ALTER TABLE public.user_monthly_tasks 
  ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE;

-- Verify the changes
SELECT 
  table_name, 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('monthly_tasks', 'user_monthly_tasks')
ORDER BY table_name, ordinal_position;
