-- App Versions Table
CREATE TABLE IF NOT EXISTS app_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  version_code INTEGER NOT NULL,
  version_name TEXT NOT NULL,
  apk_url TEXT NOT NULL,
  release_notes TEXT,
  force_update BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE app_versions;

-- Policies

-- 1. Everyone (even anon) can view versions to check for updates
CREATE POLICY "Anyone can view app versions"
  ON app_versions FOR SELECT
  TO anon, authenticated
  USING (true);

-- 2. Only Admins can insert/update versions
CREATE POLICY "Admins can manage app versions"
  ON app_versions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'Admin'
    )
  );
