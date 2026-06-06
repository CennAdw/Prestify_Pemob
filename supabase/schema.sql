-- Jalankan file ini di Supabase SQL Editor.
-- Schema produksi awal: data kosong, autentikasi memakai Supabase Auth.
-- Aktifkan Google provider dan enable Confirm email (default).
-- Supabase akan mengirim email verification secara otomatis.
-- Role tidak dipilih dari aplikasi. Email dosen harus dimasukkan ke
-- public.lecturer_allowlist oleh pengelola melalui SQL Editor.

create extension if not exists pgcrypto;

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_auth_user() cascade;
drop function if exists public.ensure_current_user_profile() cascade;
drop function if exists public.sync_user_profile(uuid, text, jsonb) cascade;
drop function if exists public.sync_user_profile(uuid, text, jsonb, jsonb) cascade;
drop function if exists public.current_user_role() cascade;
drop function if exists public.is_verified_lecturer(uuid) cascade;
drop function if exists public.is_upi_email(text) cascade;
drop function if exists public.is_active_user() cascade;

drop table if exists public.achievements cascade;
drop table if exists public.mentorship_requests cascade;
drop table if exists public.join_requests cascade;
drop table if exists public.team_members cascade;
drop table if exists public.teams cascade;
drop table if exists public.competitions cascade;
drop table if exists public.lecturers cascade;
drop table if exists public.users cascade;
drop table if exists public.lecturer_allowlist cascade;

drop policy if exists "profile photos select authenticated" on storage.objects;
drop policy if exists "profile photos insert own folder" on storage.objects;
drop policy if exists "profile photos update own folder" on storage.objects;

create table public.lecturer_allowlist (
  email text primary key check (
    email = lower(btrim(email))
    and email ~ '^[^@[:space:]]+@upi\.edu$'
  ),
  name text,
  nidn text unique,
  faculty text,
  expertise text default '',
  is_active boolean not null default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique check (
    email = lower(btrim(email))
    and email ~ '^[^@[:space:]]+@upi\.edu$'
  ),
  role text not null check (role in ('student', 'lecturer')),
  nim text unique check (nim is null or nim ~ '^[0-9]{5,30}$'),
  faculty text,
  study_program text,
  batch_year integer,
  skills text default '',
  avatar_url text,
  email_verified_at timestamptz,
  registration_completed boolean not null default false,
  portfolio_url text,
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
  nidn text unique,
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
  poster_url text,
  notes text default '',
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
  role_in_competition text,
  category text,
  level text,
  year text,
  certificate_link text,
  verification_status text default 'Menunggu Verifikasi',
  description text,
  created_at timestamptz default now()
);

create or replace function public.is_upi_email(p_email text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select lower(btrim(coalesce(p_email, ''))) ~ '^[^@[:space:]]+@upi\.edu$';
$$;

create or replace function public.sync_user_profile(
  p_user_id uuid,
  p_email text,
  p_metadata jsonb,
  p_app_metadata jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_email text := lower(btrim(coalesce(p_email, '')));
  metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  app_metadata jsonb := coalesce(p_app_metadata, '{}'::jsonb);
  display_name text;
  assigned_role text;
  provider text := lower(coalesce(app_metadata ->> 'provider', ''));
  verified_at timestamptz;
  allowlisted public.lecturer_allowlist%rowtype;
  saved_user public.users%rowtype;
begin
  if p_user_id is null or not public.is_upi_email(normalized_email) then
    raise exception 'Prestify hanya menerima email @upi.edu.';
  end if;

  display_name := coalesce(
    nullif(btrim(metadata ->> 'full_name'), ''),
    nullif(btrim(metadata ->> 'name'), ''),
    nullif(btrim(metadata ->> 'display_name'), ''),
    split_part(normalized_email, '@', 1)
  );
  verified_at := case when provider = 'google' then now() else null end;

  select *
  into allowlisted
  from public.lecturer_allowlist
  where email = normalized_email
    and is_active = true
  limit 1;

  assigned_role := case when found then 'lecturer' else 'student' end;

  insert into public.users (
    id,
    name,
    email,
    role,
    email_verified_at
  )
  values (
    p_user_id,
    display_name,
    normalized_email,
    assigned_role,
    verified_at
  )
  on conflict (id) do update
  set
    email = excluded.email,
    role = excluded.role,
    email_verified_at = coalesce(
      public.users.email_verified_at,
      excluded.email_verified_at
    ),
    name = case
      when btrim(public.users.name) = '' then excluded.name
      else public.users.name
    end,
    updated_at = now()
  returning * into saved_user;

  if assigned_role = 'lecturer' then
    insert into public.lecturers (
      id,
      name,
      email,
      nidn,
      faculty,
      expertise
    )
    values (
      p_user_id,
      coalesce(nullif(btrim(allowlisted.name), ''), saved_user.name),
      normalized_email,
      allowlisted.nidn,
      allowlisted.faculty,
      coalesce(allowlisted.expertise, '')
    )
    on conflict (id) do update
    set
      email = excluded.email,
      name = coalesce(nullif(excluded.name, ''), public.lecturers.name),
      nidn = coalesce(excluded.nidn, public.lecturers.nidn),
      faculty = coalesce(excluded.faculty, public.lecturers.faculty),
      expertise = case
        when excluded.expertise <> '' then excluded.expertise
        else public.lecturers.expertise
      end,
      updated_at = now();
  end if;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.sync_user_profile(
    new.id,
    new.email,
    new.raw_user_meta_data,
    new.raw_app_meta_data
  );
  return new;
end;
$$;

create or replace function public.ensure_current_user_profile()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  auth_user auth.users%rowtype;
begin
  select *
  into auth_user
  from auth.users
  where id = auth.uid();

  if not found then
    raise exception 'Session autentikasi tidak ditemukan.';
  end if;

  perform public.sync_user_profile(
    auth_user.id,
    auth_user.email,
    auth_user.raw_user_meta_data,
    auth_user.raw_app_meta_data
  );
end;
$$;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users
    where users.id = auth.uid()
      and users.email_verified_at is not null
      and users.registration_completed = true
      and public.is_upi_email(users.email)
  );
$$;

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when users.role = 'lecturer'
      and exists (
        select 1
        from public.lecturer_allowlist
        where lecturer_allowlist.email = lower(btrim(users.email))
          and lecturer_allowlist.is_active = true
      )
      then 'lecturer'
    when users.role = 'lecturer' then 'student'
    else users.role
  end
  from public.users
  where users.id = auth.uid()
    and users.email_verified_at is not null
    and users.registration_completed = true
    and public.is_upi_email(users.email)
  limit 1;
$$;

create or replace function public.is_verified_lecturer(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.users
    join public.lecturer_allowlist
      on lecturer_allowlist.email = lower(btrim(users.email))
    where users.id = p_user_id
      and users.role = 'lecturer'
      and users.email_verified_at is not null
      and users.registration_completed = true
      and public.is_upi_email(users.email)
      and lecturer_allowlist.is_active = true
  );
$$;

create trigger on_auth_user_created
after insert or update of email, raw_app_meta_data on auth.users
for each row execute procedure public.handle_new_auth_user();

revoke all on function public.sync_user_profile(uuid, text, jsonb, jsonb)
from public, anon, authenticated;
revoke all on function public.handle_new_auth_user()
from public, anon, authenticated;
revoke all on function public.ensure_current_user_profile()
from public, anon, authenticated;
revoke all on function public.current_user_role()
from public, anon, authenticated;
revoke all on function public.is_verified_lecturer(uuid)
from public, anon, authenticated;
revoke all on function public.is_upi_email(text)
from public, anon, authenticated;
revoke all on function public.is_active_user()
from public, anon, authenticated;

grant execute on function public.ensure_current_user_profile() to authenticated;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_verified_lecturer(uuid) to authenticated;
grant execute on function public.is_upi_email(text) to authenticated;
grant execute on function public.is_active_user() to authenticated;

alter table public.lecturer_allowlist enable row level security;
alter table public.users enable row level security;
alter table public.competitions enable row level security;
alter table public.lecturers enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.join_requests enable row level security;
alter table public.mentorship_requests enable row level security;
alter table public.achievements enable row level security;

insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('team-posters', 'team-posters', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('student-documents', 'student-documents', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('mentorship-proposals', 'mentorship-proposals', true)
on conflict (id) do nothing;

create policy "users select own profile"
on public.users for select to authenticated
using (auth.uid() = id);

create policy "users update own profile"
on public.users for update to authenticated
using (auth.uid() = id and public.is_active_user())
with check (auth.uid() = id and public.is_active_user());

create policy "competitions select authenticated"
on public.competitions for select to authenticated
using (public.is_active_user());

create policy "competitions insert student"
on public.competitions for insert to authenticated
with check (
  public.current_user_role() = 'student'
  and created_by = auth.uid()
);

create policy "lecturers select verified"
on public.lecturers for select to authenticated
using (public.is_active_user() and public.is_verified_lecturer(id));

create policy "lecturers update own profile"
on public.lecturers for update to authenticated
using (
  auth.uid() = id
  and public.current_user_role() = 'lecturer'
)
with check (
  auth.uid() = id
  and public.current_user_role() = 'lecturer'
);

create policy "teams select authenticated"
on public.teams for select to authenticated
using (public.is_active_user());

create policy "teams insert own team"
on public.teams for insert to authenticated
with check (
  leader_id = auth.uid()
  and public.current_user_role() = 'student'
);

create policy "teams update own team"
on public.teams for update to authenticated
using (
  leader_id = auth.uid()
  and public.current_user_role() = 'student'
)
with check (
  leader_id = auth.uid()
  and public.current_user_role() = 'student'
);

create policy "team_members select authenticated"
on public.team_members for select to authenticated
using (public.is_active_user());

create policy "team_members insert team leader"
on public.team_members for insert to authenticated
with check (
  public.current_user_role() = 'student'
  and exists (
    select 1
    from public.teams
    where teams.id = team_members.team_id
      and teams.leader_id = auth.uid()
  )
);

create policy "join_requests select own"
on public.join_requests for select to authenticated
using (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
);

create policy "join_requests select team leader"
on public.join_requests for select to authenticated
using (
  public.current_user_role() = 'student'
  and exists (
    select 1 from public.teams
    where teams.id = join_requests.team_id
      and teams.leader_id = auth.uid()
  )
);

create policy "join_requests insert own"
on public.join_requests for insert to authenticated
with check (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
);

create policy "join_requests update team leader"
on public.join_requests for update to authenticated
using (
  public.current_user_role() = 'student'
  and
  exists (
    select 1 from public.teams
    where teams.id = join_requests.team_id
    and teams.leader_id = auth.uid()
  )
);

create policy "mentorship_requests select lecturer"
on public.mentorship_requests for select to authenticated
using (
  lecturer_id = auth.uid()
  and public.current_user_role() = 'lecturer'
);

create policy "mentorship_requests insert team leader"
on public.mentorship_requests for insert to authenticated
with check (
  public.current_user_role() = 'student'
  and public.is_verified_lecturer(lecturer_id)
  and exists (
    select 1
    from public.teams
    where teams.id = mentorship_requests.team_id
      and teams.leader_id = auth.uid()
  )
);

create policy "mentorship_requests update lecturer"
on public.mentorship_requests for update to authenticated
using (
  lecturer_id = auth.uid()
  and public.current_user_role() = 'lecturer'
)
with check (
  lecturer_id = auth.uid()
  and public.current_user_role() = 'lecturer'
);

create policy "achievements select own"
on public.achievements for select to authenticated
using (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
);

create policy "achievements insert own"
on public.achievements for insert to authenticated
with check (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
);

create policy "achievements update own"
on public.achievements for update to authenticated
using (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
)
with check (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
);

revoke all on public.lecturer_allowlist from anon, authenticated;
revoke insert, update on public.users from anon, authenticated;
grant update (
  name,
  faculty,
  study_program,
  batch_year,
  skills,
  avatar_url,
  updated_at
)
on public.users to authenticated;
revoke insert on public.lecturers from anon, authenticated;

create policy "profile photos select authenticated"
on storage.objects for select to authenticated
using (bucket_id = 'profile-photos' and public.is_active_user());

create policy "profile photos select public"
on storage.objects for select to public
using (bucket_id = 'profile-photos');

create policy "profile photos insert own folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "profile photos update own folder"
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-photos'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-photos'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "team posters select authenticated"
on storage.objects for select to authenticated
using (bucket_id = 'team-posters' and public.is_active_user());

create policy "team posters select public"
on storage.objects for select to public
using (bucket_id = 'team-posters');

create policy "team posters insert authenticated"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'team-posters'
  and public.is_active_user()
);

create policy "team posters update authenticated"
on storage.objects for update to authenticated
using (
  bucket_id = 'team-posters'
  and public.is_active_user()
)
with check (
  bucket_id = 'team-posters'
  and public.is_active_user()
);

create policy "student documents select own"
on storage.objects for select to authenticated
using (
  bucket_id = 'student-documents'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "student documents insert own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'student-documents'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "student documents update own"
on storage.objects for update to authenticated
using (
  bucket_id = 'student-documents'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'student-documents'
  and public.is_active_user()
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "mentorship proposals select authenticated"
on storage.objects for select to authenticated
using (bucket_id = 'mentorship-proposals' and public.is_active_user());

create policy "mentorship proposals insert authenticated"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'mentorship-proposals'
  and public.is_active_user()
);

create policy "mentorship proposals update authenticated"
on storage.objects for update to authenticated
using (
  bucket_id = 'mentorship-proposals'
  and public.is_active_user()
)
with check (
  bucket_id = 'mentorship-proposals'
  and public.is_active_user()
);
