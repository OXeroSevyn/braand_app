-- Create monthly_tasks table (supports both monthly and date-specific tasks)
create table if not exists public.monthly_tasks (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  task_type text default 'monthly' check (task_type in ('monthly', 'daily')),
  month int,
  year int,
  specific_date date,
  time_limit_hours int,
  deadline_time timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_by uuid references auth.users(id),
  
  -- Constraints
  check (
    (task_type = 'monthly' and month is not null and year is not null and specific_date is null) or
    (task_type = 'daily' and specific_date is not null and month is null and year is null)
  )
);

-- Enable RLS
alter table public.monthly_tasks enable row level security;

-- Policies for monthly_tasks
create policy "Admins can insert monthly tasks"
  on public.monthly_tasks for insert
  with check (auth.uid() in (select id from public.profiles where role = 'Admin'));

create policy "Admins can update monthly tasks"
  on public.monthly_tasks for update
  using (auth.uid() in (select id from public.profiles where role = 'Admin'));

create policy "Admins can delete monthly tasks"
  on public.monthly_tasks for delete
  using (auth.uid() in (select id from public.profiles where role = 'Admin'));

create policy "Everyone can view monthly tasks"
  on public.monthly_tasks for select
  using (true);

-- Create user_monthly_tasks table to track completion per user
create table if not exists public.user_monthly_tasks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  task_id uuid references public.monthly_tasks(id) on delete cascade not null,
  is_completed boolean default false,
  completed_at timestamp with time zone,
  started_at timestamp with time zone,
  
  unique(user_id, task_id)
);

-- Enable RLS
alter table public.user_monthly_tasks enable row level security;

-- Policies for user_monthly_tasks
create policy "Users can view their own task status"
  on public.user_monthly_tasks for select
  using (auth.uid() = user_id);

create policy "Users can update their own task status"
  on public.user_monthly_tasks for update
  using (auth.uid() = user_id);

create policy "Users can insert their own task status"
  on public.user_monthly_tasks for insert
  with check (auth.uid() = user_id);

create policy "Admins can view all user task statuses"
  on public.user_monthly_tasks for select
  using (auth.uid() in (select id from public.profiles where role = 'Admin'));
