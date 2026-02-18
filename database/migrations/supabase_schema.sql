-- Create profiles table
create table profiles (
  id uuid references auth.users not null primary key,
  name text,
  email text,
  role text,
  department text,
  avatar text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for profiles
alter table profiles enable row level security;

-- Create policies for profiles
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Create attendance_records table
create table attendance_records (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) not null,
  type text not null,
  timestamp bigint not null,
  location_lat double precision,
  location_lng double precision,
  location_address text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for attendance_records
alter table attendance_records enable row level security;

-- Create policies for attendance_records
create policy "Attendance records are viewable by everyone."
  on attendance_records for select
  using ( true );

create policy "Users can insert their own attendance records."
  on attendance_records for insert
  with check ( auth.uid() = user_id );

-- Create messages table for two-way chat
create table messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references profiles(id) on delete cascade not null,
  recipient_id uuid references profiles(id) on delete cascade not null,
  message text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  read boolean default false
);

-- Create indexes for better performance
create index idx_messages_recipient on messages(recipient_id, created_at desc);
create index idx_messages_sender on messages(sender_id, created_at desc);
create index idx_messages_conversation on messages(sender_id, recipient_id, created_at desc);

-- Enable RLS for messages
alter table messages enable row level security;

-- Policy: Users can read messages they sent or received
create policy "Users can read their messages"
  on messages for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

-- Policy: Users can send messages
create policy "Users can send messages"
  on messages for insert
  with check (auth.uid() = sender_id);

-- Policy: Users can update read status of messages they received
create policy "Users can mark messages as read"
  on messages for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);
