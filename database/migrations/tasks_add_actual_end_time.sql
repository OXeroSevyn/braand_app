-- Add actual_end_time column to tasks table
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS actual_end_time TIME;

-- Add comment for documentation
COMMENT ON COLUMN public.tasks.actual_end_time IS 'Actual end time of the task (when completed)';
