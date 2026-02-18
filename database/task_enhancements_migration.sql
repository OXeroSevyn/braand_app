-- Migration: Add employee assignment, privacy, and granular time limits

-- Add new columns to monthly_tasks
ALTER TABLE public.monthly_tasks 
  ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS time_unit TEXT CHECK (time_unit IN ('minutes', 'hours', 'days'));

-- Migrate existing time_limit_hours to time_limit_minutes
UPDATE public.monthly_tasks 
SET time_limit_minutes = time_limit_hours * 60,
    time_unit = 'hours'
WHERE time_limit_hours IS NOT NULL AND time_limit_minutes IS NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_monthly_tasks_assigned_to ON public.monthly_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_monthly_tasks_is_private ON public.monthly_tasks(is_private);

-- Update RLS policy for employees to respect assignment and privacy
DROP POLICY IF EXISTS "Everyone can view monthly tasks" ON public.monthly_tasks;

CREATE POLICY "Employees can view assigned non-private tasks"
  ON public.monthly_tasks FOR SELECT
  USING (
    -- Admins can see all tasks
    (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'Admin'))
    OR
    -- Employees can see non-private tasks assigned to them or all
    (
      is_private = FALSE 
      AND (assigned_to IS NULL OR assigned_to = auth.uid())
    )
  );

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'monthly_tasks'
  AND column_name IN ('assigned_to', 'is_private', 'time_limit_minutes', 'time_unit')
ORDER BY ordinal_position;
