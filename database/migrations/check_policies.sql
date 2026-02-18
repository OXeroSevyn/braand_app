-- Step 1: Check what policies exist (run this first to see what's there)
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- If you see policies listed above, proceed with the steps below:
