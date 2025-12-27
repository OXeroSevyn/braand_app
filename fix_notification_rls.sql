-- Enable RLS on the table (good practice)
ALTER TABLE custom_notifications ENABLE ROW LEVEL SECURITY;

-- Allow ANYONE (including anon script) to INSERT notifications
-- Note: This is a convenience for the admin script.
-- For production, you should use the Service Role Key instead.
DROP POLICY IF EXISTS "Enable insert for everyone" ON custom_notifications;

CREATE POLICY "Enable insert for everyone"
ON custom_notifications FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Allow everyone to read notifications (for the app listener)
DROP POLICY IF EXISTS "Enable read access for all users" ON custom_notifications;

CREATE POLICY "Enable read access for all users"
ON custom_notifications FOR SELECT
TO anon, authenticated
USING (true);
