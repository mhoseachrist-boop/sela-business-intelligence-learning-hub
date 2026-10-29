-- Sela Business Intelligence Learning Hub — starter schema for Supabase
-- IMPORTANT: Review and test all policies before storing real student data.
-- Run in Supabase SQL Editor after creating a new project.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'student' check (role in ('student','admin','trainer')),
  created_at timestamptz not null default now()
);

create table if not exists public.programmes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text not null default '',
  description text not null default '',
  start_date date,
  end_date date,
  status text not null default 'draft' check (status in ('draft','open','active','completed','archived')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.enrolments (
  id uuid primary key default gen_random_uuid(),
  programme_id uuid not null references public.programmes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('pending','active','completed','withdrawn')),
  enrolled_at timestamptz not null default now(),
  unique (programme_id, student_id)
);

create table if not exists public.modules (
  id uuid primary key default gen_random_uuid(),
  programme_id uuid not null references public.programmes(id) on delete cascade,
  title text not null,
  description text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  title text not null,
  lesson_text text not null default '',
  resource_url text,
  storage_path text,
  content_type text not null default 'note',
  sort_order integer not null default 0,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  title text not null,
  instructions text not null default '',
  assessment_type text not null default 'quiz' check (assessment_type in ('quiz','assignment')),
  questions jsonb not null default '[]'::jsonb,
  max_score numeric not null default 100,
  due_at timestamptz,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  response jsonb not null default '{}'::jsonb,
  score numeric,
  feedback text,
  status text not null default 'submitted' check (status in ('draft','submitted','graded','returned')),
  submitted_at timestamptz not null default now(),
  graded_at timestamptz,
  graded_by uuid references public.profiles(id),
  unique (assessment_id, student_id)
);

create table if not exists public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (lesson_id, student_id)
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  programme_id uuid references public.programmes(id) on delete cascade,
  title text not null,
  body text not null,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- Enable RLS on all tables.
alter table public.profiles enable row level security;
alter table public.programmes enable row level security;
alter table public.enrolments enable row level security;
alter table public.modules enable row level security;
alter table public.lessons enable row level security;
alter table public.assessments enable row level security;
alter table public.submissions enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.announcements enable row level security;

-- Helper: profile role for signed-in user.
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

-- Profiles: a student can see/update their own basic profile; admins/trainers can view profiles.
create policy "profile select own or staff" on public.profiles
for select to authenticated
using (id = auth.uid() or public.current_user_role() in ('admin','trainer'));

create policy "profile update own" on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid() and role = (select p.role from public.profiles p where p.id = auth.uid()));

create policy "admin manages profiles" on public.profiles
for all to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

-- Programmes: authenticated users can see open/active/completed programmes; staff can manage.
create policy "read available programmes" on public.programmes
for select to authenticated
using (status in ('open','active','completed') or public.current_user_role() in ('admin','trainer'));

create policy "staff manages programmes" on public.programmes
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

-- Enrolments: students see their own enrolments; staff manage.
create policy "read own enrolments" on public.enrolments
for select to authenticated
using (student_id = auth.uid() or public.current_user_role() in ('admin','trainer'));

create policy "staff manages enrolments" on public.enrolments
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

-- Modules visible only if programme is available and user is enrolled, or user is staff.
create policy "read modules for enrolled programmes" on public.modules
for select to authenticated
using (
  public.current_user_role() in ('admin','trainer')
  or exists (
    select 1 from public.enrolments e
    join public.programmes p on p.id = e.programme_id
    where e.student_id = auth.uid()
      and e.programme_id = modules.programme_id
      and e.status = 'active'
      and p.status in ('open','active','completed')
  )
);

create policy "staff manages modules" on public.modules
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

-- Lessons and assessments: students can read published content in active enrolments; staff manage.
create policy "read published lessons" on public.lessons
for select to authenticated
using (
  (published and exists (
    select 1 from public.modules m
    join public.enrolments e on e.programme_id = m.programme_id
    where m.id = lessons.module_id and e.student_id = auth.uid() and e.status = 'active'
  ))
  or public.current_user_role() in ('admin','trainer')
);

create policy "staff manages lessons" on public.lessons
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

create policy "read published assessments" on public.assessments
for select to authenticated
using (
  (published and exists (
    select 1 from public.modules m
    join public.enrolments e on e.programme_id = m.programme_id
    where m.id = assessments.module_id and e.student_id = auth.uid() and e.status = 'active'
  ))
  or public.current_user_role() in ('admin','trainer')
);

create policy "staff manages assessments" on public.assessments
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

-- Submissions: students read/submit only their own work; staff can grade.
create policy "read own submissions or staff" on public.submissions
for select to authenticated
using (student_id = auth.uid() or public.current_user_role() in ('admin','trainer'));

create policy "students insert own submissions" on public.submissions
for insert to authenticated
with check (student_id = auth.uid());

create policy "students update own ungraded submissions" on public.submissions
for update to authenticated
using (student_id = auth.uid() and status in ('draft','submitted'))
with check (student_id = auth.uid());

create policy "staff grades submissions" on public.submissions
for update to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

-- Lesson progress: students own their progress; staff can inspect.
create policy "read own progress or staff" on public.lesson_progress
for select to authenticated
using (student_id = auth.uid() or public.current_user_role() in ('admin','trainer'));

create policy "students manage own progress" on public.lesson_progress
for all to authenticated
using (student_id = auth.uid())
with check (student_id = auth.uid());

create policy "staff reads/manages progress" on public.lesson_progress
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

create policy "read published announcements" on public.announcements
for select to authenticated
using (
  (published and (programme_id is null or exists (
    select 1 from public.enrolments e
    where e.programme_id = announcements.programme_id
      and e.student_id = auth.uid()
      and e.status = 'active'
  )))
  or public.current_user_role() in ('admin','trainer')
);

create policy "staff manages announcements" on public.announcements
for all to authenticated
using (public.current_user_role() in ('admin','trainer'))
with check (public.current_user_role() in ('admin','trainer'));

-- NOTE: Create a profile row for each auth user via a reviewed server-side trigger or admin process.
-- Do NOT let a public sign-up choose their own role. Administrator role assignment must be controlled.
-- Create private Storage buckets and explicit storage.objects RLS policies before enabling file uploads.
