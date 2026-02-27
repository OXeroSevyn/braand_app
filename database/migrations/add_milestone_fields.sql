-- Migration: Add anniversary and birthday fields to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS birthday DATE,
ADD COLUMN IF NOT EXISTS joining_date DATE DEFAULT CURRENT_DATE;

-- Add comment for clarity
COMMENT ON COLUMN public.profiles.birthday IS 'User date of birth for celebration bot';
COMMENT ON COLUMN public.profiles.joining_date IS 'Date user joined the company for work anniversary bot';
