-- First, let's check what policies exist
-- Run this to see current policies:
-- SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Drop ALL existing policies on profiles table
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;

-- Disable RLS temporarily to clean up
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies

-- 1. Allow ALL authenticated users to read ALL profiles
-- This is the simplest approach and ensures Admins can see everyone
CREATE POLICY "Allow all authenticated users to read profiles"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- 2. Allow users to insert their own profile during signup
CREATE POLICY "Allow users to insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 3. Allow users to update their own profile
CREATE POLICY "Allow users to update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Allow Admins to update ANY profile (for approval/rejection)
CREATE POLICY "Allow admins to update all profiles"
ON profiles FOR UPDATE
TO authenticated
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'Admin'
  OR
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'Admin'
);

-- 5. Allow Admins to delete profiles if needed
CREATE POLICY "Allow admins to delete profiles"
ON profiles FOR DELETE
TO authenticated
USING (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'Admin'
  OR
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'Admin'
);
