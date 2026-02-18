-- Enable RLS on profiles table if not enabled
alter table public.profiles enable row level security;

-- Drop existing policies if they conflict
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

-- Create comprehensive policies

-- 1. VIEW: Everyone can view profiles (needed for team lists, etc.)
create policy "Public profiles are viewable by everyone"
on public.profiles for select
using ( true );

-- 2. INSERT: Users can insert their own profile (Critical for Sign Up / Google Sign In)
create policy "Users can insert their own profile"
on public.profiles for insert
with check ( auth.uid() = id );

-- 3. UPDATE: Users can update their own profile
create policy "Users can update own profile"
on public.profiles for update
using ( auth.uid() = id );

-- Grant permissions to authenticated users
grant usage on schema public to authenticated;
grant all on public.profiles to authenticated;
