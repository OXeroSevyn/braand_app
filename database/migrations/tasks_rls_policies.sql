-- Enable Row Level Security for tasks table (if not already enabled)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Employees can view their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Employees can insert their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Employees can update their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Employees can delete their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Admins can view all tasks" ON public.tasks;

-- Policy: Employees can view their own tasks
CREATE POLICY "Employees can view their own tasks"
  ON public.tasks FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Employees can insert their own tasks
CREATE POLICY "Employees can insert their own tasks"
  ON public.tasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Employees can update their own tasks
CREATE POLICY "Employees can update their own tasks"
  ON public.tasks FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Employees can delete their own tasks
CREATE POLICY "Employees can delete their own tasks"
  ON public.tasks FOR DELETE
  USING (auth.uid() = user_id);

-- Policy: Admins can view all tasks (for reports)
CREATE POLICY "Admins can view all tasks"
  ON public.tasks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );

