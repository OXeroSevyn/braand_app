-- Leave Balances Table
CREATE TABLE IF NOT EXISTS leave_balances (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  year INT NOT NULL,
  total_leaves INT DEFAULT 12,
  used_leaves INT DEFAULT 0,
  pending_leaves INT DEFAULT 0, -- Optional: helps UI show "Potential Remaining"
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, year)
);

-- Enable RLS
ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE leave_balances;

-- Policies

-- 1. Users can view their own leave balance
CREATE POLICY "Users can view own leave balance"
  ON leave_balances FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 2. Admins can view all leave balances
CREATE POLICY "Admins can view all leave balances"
  ON leave_balances FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );

-- 3. Admins can update leave balances (e.g. adjust total, or deduct manually)
CREATE POLICY "Admins can update leave balances"
  ON leave_balances FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );

-- 4. Users cannot insert/update/delete strictly (managed by system/admin)
-- But if we want auto-create on first access via client, we might need INSERT.
-- However, we'll likely use a stored procedure or admin-privileged service call, or just allow INSERT for own user if no record exists?
-- Better: "Users can insert own balance" if not exists (for lazy init), or "Admins insert".
-- Let's allow users to INSERT their own initial record if needed by the app logic:
CREATE POLICY "Users can insert own leave balance"
  ON leave_balances FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
