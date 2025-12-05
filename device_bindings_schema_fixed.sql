-- Device Bindings Table (FIXED VERSION)
-- Stores device-to-employee mappings to prevent device sharing

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own devices" ON device_bindings;
DROP POLICY IF EXISTS "Users can register own devices" ON device_bindings;
DROP POLICY IF EXISTS "Users can update own devices" ON device_bindings;
DROP POLICY IF EXISTS "Admins can view all devices" ON device_bindings;
DROP POLICY IF EXISTS "Admins can manage all devices" ON device_bindings;

-- Create table if it doesn't exist
CREATE TABLE IF NOT EXISTS device_bindings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_name TEXT,
  device_model TEXT,
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(user_id, device_id)
);

-- Enable Row Level Security
ALTER TABLE device_bindings ENABLE ROW LEVEL SECURITY;

-- SIMPLIFIED POLICIES - Allow authenticated users to manage their own devices

-- Users can view their own devices
CREATE POLICY "Users can view own devices"
  ON device_bindings FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can register their own devices
CREATE POLICY "Users can register own devices"
  ON device_bindings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own devices
CREATE POLICY "Users can update own devices"
  ON device_bindings FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can delete their own devices
CREATE POLICY "Users can delete own devices"
  ON device_bindings FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_device_bindings_user_id ON device_bindings(user_id);
CREATE INDEX IF NOT EXISTS idx_device_bindings_device_id ON device_bindings(device_id);
