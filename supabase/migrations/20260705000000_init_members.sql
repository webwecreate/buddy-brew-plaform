-- Buddy Brew member platform — Phase 1 schema
-- Run this in Supabase SQL editor after creating the project.

create table members (
  id uuid primary key default gen_random_uuid(),
  line_user_id text unique not null,
  display_name text not null,
  picture_url text,
  tier text not null default 'sip',
  point integer not null default 0,
  birthday date,
  staff_photo_url text,
  staff_note text,
  created_at timestamptz not null default now()
);

-- Row Level Security on, with zero policies defined.
-- Result: only the service_role key (used by edge functions) can read/write this table.
-- The anon/public key used by the LIFF frontend cannot touch it directly at all —
-- every read/write must go through a verified edge function.
alter table members enable row level security;
