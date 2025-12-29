-- Create a secure function to fetch FCM tokens
-- SECURITY DEFINER means it runs with the privileges of the creator (postgres/admin)
-- bypassing RLS policies that might block the Anon key.

CREATE OR REPLACE FUNCTION get_fcm_tokens()
RETURNS TABLE (fcm_token text)
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT p.fcm_token
  FROM profiles p
  WHERE p.fcm_token IS NOT NULL AND p.fcm_token != 'null';
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to anon/authenticated users
GRANT EXECUTE ON FUNCTION get_fcm_tokens() TO anon, authenticated, service_role;
