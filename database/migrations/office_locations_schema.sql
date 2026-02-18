-- Office Locations Table
-- Stores office locations for geofencing verification

CREATE TABLE IF NOT EXISTS office_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  radius_meters INTEGER DEFAULT 100,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE office_locations ENABLE ROW LEVEL SECURITY;

-- Everyone can view active locations
CREATE POLICY "Everyone can view active locations"
  ON office_locations FOR SELECT
  USING (is_active = true);

-- Only admins can insert locations
CREATE POLICY "Only admins can insert locations"
  ON office_locations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can update locations
CREATE POLICY "Only admins can update locations"
  ON office_locations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Only admins can delete locations
CREATE POLICY "Only admins can delete locations"
  ON office_locations FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create index for faster lookups
CREATE INDEX idx_office_locations_active ON office_locations(is_active);

-- Insert default office location (update coordinates as needed)
INSERT INTO office_locations (name, latitude, longitude, radius_meters)
VALUES ('Main Office', 0.0, 0.0, 100)
ON CONFLICT DO NOTHING;
