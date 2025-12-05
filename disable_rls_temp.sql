-- TEMPORARY FIX: Disable RLS for Office Locations
-- This will help us test if RLS is the problem
-- Run this in Supabase SQL Editor

-- Disable RLS on office_locations table
ALTER TABLE office_locations DISABLE ROW LEVEL SECURITY;

-- Check if there are any existing locations
SELECT * FROM office_locations;
