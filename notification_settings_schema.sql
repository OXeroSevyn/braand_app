-- Notification Settings Table
CREATE TABLE IF NOT EXISTS notification_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL CHECK (type IN ('clock_in', 'clock_out', 'break_reminder', 'custom_message')),
  enabled BOOLEAN DEFAULT true,
  time TEXT NOT NULL, -- Format: "HH:mm"
  message TEXT NOT NULL,
  days_of_week TEXT[] DEFAULT ARRAY['mon', 'tue', 'wed', 'thu', 'fri'],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default notification settings
INSERT INTO notification_settings (type, enabled, time, message, days_of_week) VALUES
  ('clock_in', true, '09:00', 'Good morning! Time to clock in 🌅', ARRAY['mon', 'tue', 'wed', 'thu', 'fri']),
  ('clock_out', true, '18:00', 'Don''t forget to clock out! 🏠', ARRAY['mon', 'tue', 'wed', 'thu', 'fri']),
  ('break_reminder', false, '12:00', 'Time for a break! ☕', ARRAY['mon', 'tue', 'wed', 'thu', 'fri']),
  ('custom_message', false, '10:00', 'Important announcement from management 📢', ARRAY['mon', 'tue', 'wed', 'thu', 'fri'])
ON CONFLICT DO NOTHING;

-- Enable Row Level Security
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all authenticated users to read notification settings
CREATE POLICY "Allow authenticated users to read notification settings"
  ON notification_settings
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Only admins can update notification settings
CREATE POLICY "Only admins can update notification settings"
  ON notification_settings
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );

-- Policy: Only admins can insert notification settings
CREATE POLICY "Only admins can insert notification settings"
  ON notification_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );

-- Policy: Only admins can delete notification settings
CREATE POLICY "Only admins can delete notification settings"
  ON notification_settings
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );
