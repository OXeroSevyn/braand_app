-- Add bio and phone fields to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Migrate existing avatar data to avatar_url if needed
UPDATE profiles
SET avatar_url = avatar
WHERE avatar IS NOT NULL AND avatar_url IS NULL;

-- Optional: Drop old avatar column if you want to clean up
-- ALTER TABLE profiles DROP COLUMN IF EXISTS avatar;
