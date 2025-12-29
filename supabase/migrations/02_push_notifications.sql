-- Migration: Add Push Notification fields to profiles
-- Run this in Supabase SQL Editor

-- 1. Create or Update profiles table
create table if not exists public.profiles (
  id uuid references auth.users not null primary key,
  username text,
  full_name text,
  avatar_url text,
  expo_push_token text,
  streak_count int default 0,
  last_active_at timestamp with time zone default now(),
  preferred_language text default 'English',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Add columns if table already exists (for safety)
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'expo_push_token') then
    alter table public.profiles add column expo_push_token text;
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'streak_count') then
    alter table public.profiles add column streak_count int default 0;
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'last_active_at') then
    alter table public.profiles add column last_active_at timestamp with time zone default now();
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'preferred_language') then
    alter table public.profiles add column preferred_language text default 'English';
  end if;
end $$;

-- 3. Enable RLS
alter table public.profiles enable row level security;

-- 4. Policies
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );
