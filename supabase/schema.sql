-- Jalankan file ini di Supabase SQL Editor.
-- Schema produksi awal: data kosong, autentikasi memakai Supabase Auth Google.
-- Aktifkan Google provider di Authentication > Providers sebelum digunakan.

create extension if not exists pgcrypto;

drop table if exists public.achievements cascade;
drop table if exists public.mentorship_requests cascade;
drop table if exists public.join_requests cascade;
drop table if exists public.team_members cascade;
drop table if exists public.teams cascade;
drop table if exists public.competitions cascade;
drop table if exists public.lecturers cascade;
drop table if exists public.users cascade;

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  role text not null check (role in ('student', 'lecturer')),
  study_program text,
  batch_year integer,
  skills text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.competitions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  organizer text,
  category text,
  level text,
  deadline text,
  description text,
  registration_link text,
  verification_status text default 'Menunggu Verifikasi',
  interest_count integer default 0,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz default now()
);

create table public.lecturers (
  id uuid primary key references public.users(id) on delete cascade,
  name text not null,
  email text unique,
  faculty text,
  expertise text default '',
  mentoring_status text default 'Tersedia',
  mentoring_quota integer default 5,
  current_mentoring_count integer default 0,
  experiences text default '',
  bio text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  competition_name text not null,
  leader_id uuid references public.users(id) on delete set null,
  team_name text not null,
  description text,
  required_roles text,
  required_skills text default '',
  recruitment_status text default 'Open Recruitment',
  progress_status text default 'Recruiting',
  mentor_id uuid references public.lecturers(id) on delete set null,
  deadline text default 'Belum ditentukan',
  matching_score integer default 0,
  current_members integer default 1,
  max_members integer default 5,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete cascade,
  student_id uuid references public.users(id) on delete cascade,
  name text not null,
  role_in_team text not null,
  joined_at timestamptz default now()
);

create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete cascade,
  student_id uuid references public.users(id) on delete cascade,
  applied_role text not null,
  message text,
  matching_score integer default 0,
  status text default 'Menunggu',
  created_at timestamptz default now()
);

create table public.mentorship_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete cascade,
  lecturer_id uuid references public.lecturers(id) on delete cascade,
  proposal_title text not null,
  proposal_summary text,
  proposal_link text,
  status text default 'Menunggu',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.achievements (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.users(id) on delete cascade,
  team_id uuid references public.teams(id) on delete set null,
  competition_name text not null,
  award text not null,
  category text,
  level text,
  year text,
  certificate_link text,
  verification_status text default 'Menunggu Verifikasi',
  description text,
  created_at timestamptz default now()
);

alter table public.users enable row level security;
alter table public.competitions enable row level security;
alter table public.lecturers enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.join_requests enable row level security;
alter table public.mentorship_requests enable row level security;
alter table public.achievements enable row level security;

create policy "users select own profile"
on public.users for select to authenticated
using (auth.uid() = id);

create policy "users insert own profile"
on public.users for insert to authenticated
with check (auth.uid() = id);

create policy "users update own profile"
on public.users for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "competitions select authenticated"
on public.competitions for select to authenticated
using (true);

create policy "competitions insert authenticated"
on public.competitions for insert to authenticated
with check (created_by is null or created_by = auth.uid());

create policy "lecturers select authenticated"
on public.lecturers for select to authenticated
using (true);

create policy "lecturers insert own profile"
on public.lecturers for insert to authenticated
with check (auth.uid() = id);

create policy "lecturers update own profile"
on public.lecturers for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "teams select authenticated"
on public.teams for select to authenticated
using (true);

create policy "teams insert own team"
on public.teams for insert to authenticated
with check (leader_id = auth.uid());

create policy "teams update own team"
on public.teams for update to authenticated
using (leader_id = auth.uid())
with check (leader_id = auth.uid());

create policy "team_members select authenticated"
on public.team_members for select to authenticated
using (true);

create policy "team_members insert authenticated"
on public.team_members for insert to authenticated
with check (true);

create policy "join_requests select own"
on public.join_requests for select to authenticated
using (student_id = auth.uid());

create policy "join_requests insert own"
on public.join_requests for insert to authenticated
with check (student_id = auth.uid());

create policy "join_requests update team leader"
on public.join_requests for update to authenticated
using (
  exists (
    select 1 from public.teams
    where teams.id = join_requests.team_id
    and teams.leader_id = auth.uid()
  )
);

create policy "mentorship_requests select lecturer"
on public.mentorship_requests for select to authenticated
using (lecturer_id = auth.uid());

create policy "mentorship_requests insert authenticated"
on public.mentorship_requests for insert to authenticated
with check (true);

create policy "mentorship_requests update lecturer"
on public.mentorship_requests for update to authenticated
using (lecturer_id = auth.uid())
with check (lecturer_id = auth.uid());

create policy "achievements select own"
on public.achievements for select to authenticated
using (student_id = auth.uid());

create policy "achievements insert own"
on public.achievements for insert to authenticated
with check (student_id = auth.uid());

create policy "achievements update own"
on public.achievements for update to authenticated
using (student_id = auth.uid())
with check (student_id = auth.uid());
