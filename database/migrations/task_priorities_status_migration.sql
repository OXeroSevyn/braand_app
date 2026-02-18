-- Add priority to monthly_tasks
ALTER TABLE monthly_tasks
ADD COLUMN priority TEXT DEFAULT 'Medium';

-- Add check constraint for priority
ALTER TABLE monthly_tasks
ADD CONSTRAINT check_priority CHECK (priority IN ('Low', 'Medium', 'High', 'Urgent'));

-- Add status to user_monthly_tasks
ALTER TABLE user_monthly_tasks
ADD COLUMN status TEXT DEFAULT 'Pending';

-- Add check constraint for status
ALTER TABLE user_monthly_tasks
ADD CONSTRAINT check_status CHECK (status IN ('Pending', 'In Progress', 'Completed', 'On Hold', 'Review'));

-- Migrate existing data: If is_completed is true, set status to 'Completed'
UPDATE user_monthly_tasks
SET status = 'Completed'
WHERE is_completed = true;

-- Migrate existing data: If is_completed is false, set status to 'Pending' (default, but good to be explicit for clarity if needed, though default handles new rows)
UPDATE user_monthly_tasks
SET status = 'Pending'
WHERE is_completed = false AND status IS NULL;
