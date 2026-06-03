-- Jalankan migration ini jika schema Prestify sudah pernah dipasang.
-- Role dosen hanya diberikan kepada email aktif di public.lecturer_allowlist.
-- Akun lecturer lama yang belum ada di allowlist akan diubah menjadi student.

create table if not exists public.lecturer_allowlist (
  email text primary key check (email = lower(btrim(email))),
  name text,
  nidn text,
  faculty text,
  expertise text default '',
  is_active boolean not null default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.lecturers
add column if not exists nidn text;

-- Masukkan email dosen resmi sebelum bagian SECURITY RESET jika akun dosen
-- yang sudah ada harus tetap menjadi lecturer.
--
-- insert into public.lecturer_allowlist (
--   email, name, nidn, faculty, expertise
-- ) values (
--   'nama.dosen@upi.edu',
--   'Nama Dosen',
--   'NIDN',
--   'Fakultas',
--   'Mobile Development, Sistem Informasi'
-- );

-- SECURITY RESET: role lecturer lama yang tidak terverifikasi diturunkan.
update public.users
set
  role = 'student',
  updated_at = now()
where role = 'lecturer'
  and not exists (
    select 1
    from public.lecturer_allowlist
    where lecturer_allowlist.email = lower(btrim(users.email))
      and lecturer_allowlist.is_active = true
  );

create or replace function public.sync_user_profile(
  p_user_id uuid,
  p_email text,
  p_metadata jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_email text := lower(btrim(coalesce(p_email, '')));
  metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
  display_name text;
  assigned_role text;
  allowlisted public.lecturer_allowlist%rowtype;
  saved_user public.users%rowtype;
begin
  if p_user_id is null or normalized_email = '' then
    raise exception 'Akun Google tidak memiliki id atau email yang valid.';
  end if;

  display_name := coalesce(
    nullif(btrim(metadata ->> 'full_name'), ''),
    nullif(btrim(metadata ->> 'name'), ''),
    nullif(btrim(metadata ->> 'display_name'), ''),
    split_part(normalized_email, '@', 1)
  );

  select *
  into allowlisted
  from public.lecturer_allowlist
  where email = normalized_email
    and is_active = true
  limit 1;

  assigned_role := case when found then 'lecturer' else 'student' end;

  insert into public.users (id, name, email, role)
  values (p_user_id, display_name, normalized_email, assigned_role)
  on conflict (id) do update
  set
    email = excluded.email,
    role = excluded.role,
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
  perform public.sync_user_profile(new.id, new.email, new.raw_user_meta_data);
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
    auth_user.raw_user_meta_data
  );
end;
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
      and lecturer_allowlist.is_active = true
  );
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert or update of email on auth.users
for each row execute procedure public.handle_new_auth_user();

revoke all on function public.sync_user_profile(uuid, text, jsonb)
from public, anon, authenticated;
revoke all on function public.handle_new_auth_user()
from public, anon, authenticated;
revoke all on function public.ensure_current_user_profile()
from public, anon, authenticated;
revoke all on function public.current_user_role()
from public, anon, authenticated;
revoke all on function public.is_verified_lecturer(uuid)
from public, anon, authenticated;

grant execute on function public.ensure_current_user_profile() to authenticated;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_verified_lecturer(uuid) to authenticated;

alter table public.lecturer_allowlist enable row level security;

drop policy if exists "users insert own profile" on public.users;
drop policy if exists "users select own profile" on public.users;
drop policy if exists "users update own profile" on public.users;
drop policy if exists "competitions insert authenticated" on public.competitions;
drop policy if exists "competitions insert student" on public.competitions;
drop policy if exists "lecturers select authenticated" on public.lecturers;
drop policy if exists "lecturers select verified" on public.lecturers;
drop policy if exists "lecturers insert own profile" on public.lecturers;
drop policy if exists "lecturers update own profile" on public.lecturers;
drop policy if exists "teams insert own team" on public.teams;
drop policy if exists "teams update own team" on public.teams;
drop policy if exists "team_members insert authenticated" on public.team_members;
drop policy if exists "team_members insert team leader" on public.team_members;
drop policy if exists "join_requests select own" on public.join_requests;
drop policy if exists "join_requests insert own" on public.join_requests;
drop policy if exists "join_requests update team leader" on public.join_requests;
drop policy if exists "mentorship_requests select lecturer" on public.mentorship_requests;
drop policy if exists "mentorship_requests insert authenticated" on public.mentorship_requests;
drop policy if exists "mentorship_requests insert team leader" on public.mentorship_requests;
drop policy if exists "mentorship_requests update lecturer" on public.mentorship_requests;
drop policy if exists "achievements select own" on public.achievements;
drop policy if exists "achievements insert own" on public.achievements;
drop policy if exists "achievements update own" on public.achievements;

create policy "users select own profile"
on public.users for select to authenticated
using (auth.uid() = id);

create policy "users update own profile"
on public.users for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "competitions insert student"
on public.competitions for insert to authenticated
with check (
  public.current_user_role() = 'student'
  and created_by = auth.uid()
);

create policy "lecturers select verified"
on public.lecturers for select to authenticated
using (public.is_verified_lecturer(id));

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
  and exists (
    select 1
    from public.teams
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
grant update (name, study_program, batch_year, skills, avatar_url, updated_at)
on public.users to authenticated;
revoke insert on public.lecturers from anon, authenticated;
