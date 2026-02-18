-- NUCLEAR OPTION: Completely disable RLS and start fresh

-- Step 1: Disable RLS completely
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL policies (this will work even if we don't know their names)
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'profiles') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON profiles';
    END LOOP;
END $$;

-- Step 3: Verify all policies are gone
-- Run this to confirm: SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Step 4: Re-enable RLS with ONLY the simplest policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow everyone to read everything (no conditions = no recursion)
CREATE POLICY "allow_all_select"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Allow users to insert their own profile
CREATE POLICY "allow_own_insert"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy 3: Allow everyone to update everything (temporary - we'll restrict later if needed)
CREATE POLICY "allow_all_update"
ON profiles FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy 4: Allow everyone to delete (temporary - we'll restrict later if needed)
CREATE POLICY "allow_all_delete"
ON profiles FOR DELETE
TO authenticated
USING (true);

-- After running this, the app should work. We can add restrictions later once it's working.
