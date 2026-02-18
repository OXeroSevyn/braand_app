-- Add start_time and end_time columns to tasks table
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS start_time TIME,
ADD COLUMN IF NOT EXISTS end_time TIME;

-- Add comment for documentation
COMMENT ON COLUMN public.tasks.start_time IS 'Start time of the task (HH:MM format)';
COMMENT ON COLUMN public.tasks.end_time IS 'End time of the task (HH:MM format)';

