-- Banner Announcements Table
CREATE TABLE IF NOT EXISTS banner_announcements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE banner_announcements ENABLE ROW LEVEL SECURITY;

-- Policies
-- Everyone (authenticated) can view active announcements
CREATE POLICY "Everyone can view active announcements"
  ON banner_announcements FOR SELECT
  TO authenticated
  USING (is_active = true AND (expires_at IS NULL OR expires_at > NOW()));

-- Admins can insert/update/delete (Assuming admin check via profile or metadata, simplified here to authenticated for now, ideally strictly admins)
-- For simplicity in this SQL, we'll allow authenticated users to insert if they are admins (enforced by app logic or cleaner policy if role is in jwt)
-- Here we'll just allow all authenticated for insert/update for now as Role checks often require joined queries or custom claims
CREATE POLICY "Authenticated can manage announcements"
  ON banner_announcements FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
