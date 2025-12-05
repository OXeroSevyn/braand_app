-- Device Bindings Table
-- Stores device-to-employee mappings to prevent device sharing

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

-- Users can view their own devices
CREATE POLICY "Users can view own devices"
  ON device_bindings FOR SELECT
  USING (auth.uid() = user_id);

-- Users can register their own devices
CREATE POLICY "Users can register own devices"
  ON device_bindings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own devices
CREATE POLICY "Users can update own devices"
  ON device_bindings FOR UPDATE
  USING (auth.uid() = user_id);

-- Admins can view all devices
CREATE POLICY "Admins can view all devices"
  ON device_bindings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can manage all devices
CREATE POLICY "Admins can manage all devices"
  ON device_bindings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create index for faster lookups
CREATE INDEX idx_device_bindings_user_id ON device_bindings(user_id);
CREATE INDEX idx_device_bindings_device_id ON device_bindings(device_id);
