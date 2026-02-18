-- Add admin_assessment and priority columns to tasks table

ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS admin_assessment text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS priority text DEFAULT 'normal';

-- Add check constraint for admin_assessment
ALTER TABLE public.tasks 
DROP CONSTRAINT IF EXISTS tasks_admin_assessment_check;

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_admin_assessment_check 
CHECK (admin_assessment IN ('pending', 'accepted', 'rejected'));

-- Add check constraint for priority
ALTER TABLE public.tasks 
DROP CONSTRAINT IF EXISTS tasks_priority_check;

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_priority_check 
CHECK (priority IN ('normal', 'urgent'));

-- RLS Update: Allow admins to update strict fields
CREATE POLICY "Admins can update task attributes" 
ON public.tasks 
FOR UPDATE 
TO authenticated 
USING (
  exists (
    select 1 from profiles
    where profiles.id = auth.uid()
    and profiles.role = 'Admin'
  )
)
WITH CHECK (
  exists (
    select 1 from profiles
    where profiles.id = auth.uid()
    and profiles.role = 'Admin'
  )
);

-- RLS Update: Allow ALL authenticated users to READ ALL tasks (for Leaderboard)
-- This is critical so employees can see others' scores.
-- Drop existing select policy if it interferes, or ensure this one is additive.
-- Assuming a restrictive policy exists like "Users can view their own tasks only",
-- we need to broaden it or add a new one.

DROP POLICY IF EXISTS "Enable read access for all users" ON public.tasks;

CREATE POLICY "Enable read access for all users"
ON public.tasks
FOR SELECT
TO authenticated
USING (true);
