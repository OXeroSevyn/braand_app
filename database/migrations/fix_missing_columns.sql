-- Fix missing columns in profiles and attendance_records tables

-- 1. Add 'status' column to profiles table
-- This is critical for the approval flow. Without it, users are stuck in 'pending' state.
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- Update existing profiles to 'active' if they are admins or specifically subhamdey.one@gmail.com
UPDATE public.profiles
SET status = 'active'
WHERE role = 'Admin' OR email = 'subhamdey.one@gmail.com';

-- 2. Add 'mood' column to attendance_records table
-- This is required by the app's clock-in process. 
ALTER TABLE public.attendance_records
ADD COLUMN IF NOT EXISTS mood TEXT;

-- 3. Ensure all columns for attendance_records exist (safety check)
ALTER TABLE public.attendance_records
ADD COLUMN IF NOT EXISTS device_id TEXT,
ADD COLUMN IF NOT EXISTS biometric_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS photo_url TEXT,
ADD COLUMN IF NOT EXISTS verification_method TEXT;

-- 4. Fix RLS for profiles (ensure admins can update status)
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
CREATE POLICY "Admins can update any profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'Admin'
)
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'Admin'
);

-- 5. Fix RLS for attendance_records (ensure everyone can select)
DROP POLICY IF EXISTS "Attendance records are viewable by everyone." ON public.attendance_records;
CREATE POLICY "Attendance records are viewable by everyone."
ON public.attendance_records FOR SELECT
TO authenticated
USING ( true );
