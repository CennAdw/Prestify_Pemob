-- Jalankan migration ini setelah 20260603_secure_role_assignment.sql.
-- Menambahkan NIM, pendaftaran akun, verifikasi email Resend, dan pembatasan
-- akses data sampai email terverifikasi serta profil pendaftaran lengkap.

alter table public.users
add column if not exists nim text,
add column if not exists faculty text,
add column if not exists email_verified_at timestamptz,
add column if not exists registration_completed boolean not null default false;

create unique index if not exists users_nim_unique_idx
on public.users (nim)
where nim is not null;

create unique index if not exists lecturers_nidn_unique_idx
on public.lecturers (nidn)
where nidn is not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_nim_format_check'
  ) then
    alter table public.users
    add constraint users_nim_format_check
    check (nim is null or nim ~ '^[0-9]{5,30}$');
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_upi_email_check'
  ) then
    alter table public.users
    add constraint users_upi_email_check
    check (
      email = lower(btrim(email))
      and email ~ '^[^@[:space:]]+@upi\.edu$'
    ) not valid;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'lecturer_allowlist_upi_email_check'
  ) then
    alter table public.lecturer_allowlist
    add constraint lecturer_allowlist_upi_email_check
    check (
      email = lower(btrim(email))
      and email ~ '^[^@[:space:]]+@upi\.edu$'
    ) not valid;
  end if;
end;
$$;

create table if not exists public.email_verification_codes (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  code_hash text not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  attempts integer not null default 0,
  sent_count integer not null default 1,
  window_started_at timestamptz not null default now(),
  last_sent_at timestamptz not null default now(),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Semua akun lama Prestify berasal dari Google, jadi email @upi.edu lama dapat
-- dianggap telah diverifikasi oleh provider Google.
update public.users
set email_verified_at = coalesce(email_verified_at, now())
where lower(btrim(email)) ~ '^[^@[:space:]]+@upi\.edu$';

-- Mahasiswa lama diminta melengkapi NIM saat login berikutnya.
update public.users
set registration_completed = case
  when role = 'lecturer' then exists (
    select 1
    from public.lecturers
    where lecturers.id = users.id
      and lecturers.nidn is not null
  )
  else nim is not null
end;

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_auth_user();
drop function if exists public.ensure_current_user_profile();
drop function if exists public.sync_user_profile(uuid, text, jsonb);
drop function if exists public.sync_user_profile(uuid, text, jsonb, jsonb);

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

alter table public.email_verification_codes enable row level security;

drop policy if exists "users update own profile" on public.users;
drop policy if exists "competitions select authenticated" on public.competitions;
drop policy if exists "lecturers select authenticated" on public.lecturers;
drop policy if exists "lecturers select verified" on public.lecturers;
drop policy if exists "teams select authenticated" on public.teams;
drop policy if exists "team_members select authenticated" on public.team_members;

create policy "users update own profile"
on public.users for update to authenticated
using (auth.uid() = id and public.is_active_user())
with check (auth.uid() = id and public.is_active_user());

create policy "competitions select authenticated"
on public.competitions for select to authenticated
using (public.is_active_user());

create policy "lecturers select verified"
on public.lecturers for select to authenticated
using (public.is_active_user() and public.is_verified_lecturer(id));

create policy "teams select authenticated"
on public.teams for select to authenticated
using (public.is_active_user());

create policy "team_members select authenticated"
on public.team_members for select to authenticated
using (public.is_active_user());

revoke all on public.email_verification_codes from anon, authenticated;
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

drop policy if exists "profile photos select authenticated" on storage.objects;
drop policy if exists "profile photos insert own folder" on storage.objects;
drop policy if exists "profile photos update own folder" on storage.objects;

create policy "profile photos select authenticated"
on storage.objects for select to authenticated
using (bucket_id = 'profile-photos' and public.is_active_user());

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
