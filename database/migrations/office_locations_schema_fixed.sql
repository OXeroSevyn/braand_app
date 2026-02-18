-- Office Locations Table (FIXED VERSION)
-- Stores office locations for geofencing verification

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Everyone can view active locations" ON office_locations;
DROP POLICY IF EXISTS "Only admins can insert locations" ON office_locations;
DROP POLICY IF EXISTS "Only admins can update locations" ON office_locations;
DROP POLICY IF EXISTS "Only admins can delete locations" ON office_locations;

-- Create table if it doesn't exist
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

-- SIMPLIFIED POLICIES - Allow all authenticated users
-- (You can restrict this later once it's working)

-- Everyone authenticated can view locations
CREATE POLICY "Authenticated users can view locations"
  ON office_locations FOR SELECT
  TO authenticated
  USING (true);

-- Authenticated users can insert locations
CREATE POLICY "Authenticated users can insert locations"
  ON office_locations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Authenticated users can update locations
CREATE POLICY "Authenticated users can update locations"
  ON office_locations FOR UPDATE
  TO authenticated
  USING (true);

-- Authenticated users can delete locations
CREATE POLICY "Authenticated users can delete locations"
  ON office_locations FOR DELETE
  TO authenticated
  USING (true);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_office_locations_active ON office_locations(is_active);
