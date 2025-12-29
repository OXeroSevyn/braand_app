-- Add fcm_token column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token text;

-- Add index on fcm_token for faster lookups (optional but good practice)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token);
