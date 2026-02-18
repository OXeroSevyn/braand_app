-- FINAL FIX: Simple RLS policies without recursion

-- Drop ALL existing policies on profiles table
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;
DROP POLICY IF EXISTS "Allow all authenticated users to read profiles" ON profiles;
DROP POLICY IF EXISTS "Allow users to insert own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to update own profile" ON profiles;
DROP POLICY IF EXISTS "Allow admins to update all profiles" ON profiles;
DROP POLICY IF EXISTS "Allow admins to delete profiles" ON profiles;

-- Disable and re-enable RLS to clean up
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- SIMPLE POLICIES (NO RECURSION)

-- 1. Everyone can read all profiles (simplest solution)
CREATE POLICY "authenticated_read_all"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- 2. Users can insert their own profile during signup
CREATE POLICY "users_insert_own"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 3. Users can update their own profile
CREATE POLICY "users_update_own"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Admins can update any profile (using user_metadata only, no table lookup)
CREATE POLICY "admins_update_all"
ON profiles FOR UPDATE
TO authenticated
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'Admin'
);

-- 5. Admins can delete any profile (using user_metadata only)
CREATE POLICY "admins_delete_all"
ON profiles FOR DELETE
TO authenticated
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'Admin'
);
