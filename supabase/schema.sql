-- Jalankan file ini di Supabase SQL Editor.
-- MVP demo: policy dibuat terbuka agar Flutter client anon key bisa baca/tulis.
-- Untuk produksi, ganti dengan Supabase Auth + RLS per user.

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
  id text primary key,
  name text not null,
  email text not null unique,
  password text not null,
  role text not null check (role in ('student', 'lecturer')),
  study_program text,
  batch_year integer,
  skills text,
  created_at timestamptz default now()
);

create table public.competitions (
  id text primary key default gen_random_uuid()::text,
  title text not null,
  organizer text,
  category text,
  level text,
  deadline text,
  description text,
  registration_link text,
  verification_status text default 'Terverifikasi',
  interest_count integer default 0,
  created_at timestamptz default now()
);

create table public.teams (
  id text primary key default gen_random_uuid()::text,
  competition_name text not null,
  leader_id text references public.users(id) on delete set null,
  team_name text not null,
  description text,
  required_roles text,
  required_skills text,
  recruitment_status text default 'Open Recruitment',
  progress_status text default 'Recruiting',
  mentor_id text,
  deadline text default 'Belum ditentukan',
  matching_score integer default 70,
  current_members integer default 1,
  max_members integer default 5,
  created_at timestamptz default now()
);

create table public.team_members (
  id text primary key default gen_random_uuid()::text,
  team_id text references public.teams(id) on delete cascade,
  name text not null,
  role_in_team text not null,
  joined_at timestamptz default now()
);

create table public.join_requests (
  id text primary key default gen_random_uuid()::text,
  team_id text references public.teams(id) on delete cascade,
  student_id text references public.users(id) on delete cascade,
  applied_role text not null,
  message text,
  matching_score integer default 0,
  status text default 'Menunggu',
  created_at timestamptz default now()
);

create table public.lecturers (
  id text primary key,
  name text not null,
  email text,
  faculty text,
  expertise text,
  mentoring_status text default 'Tersedia',
  mentoring_quota integer default 5,
  current_mentoring_count integer default 0,
  experiences text,
  bio text,
  created_at timestamptz default now()
);

create table public.mentorship_requests (
  id text primary key default gen_random_uuid()::text,
  team_id text references public.teams(id) on delete cascade,
  lecturer_id text references public.lecturers(id) on delete cascade,
  proposal_title text not null,
  proposal_summary text,
  proposal_link text,
  status text default 'Menunggu',
  created_at timestamptz default now()
);

create table public.achievements (
  id text primary key default gen_random_uuid()::text,
  student_id text references public.users(id) on delete cascade,
  team_id text references public.teams(id) on delete set null,
  competition_name text not null,
  award text not null,
  category text,
  level text,
  year text,
  certificate_link text,
  verification_status text default 'Terverifikasi',
  description text
);

insert into public.users (id, name, email, password, role, study_program, batch_year, skills) values
('student-candra', 'Candra', 'candra@upi.edu', '123456', 'student', 'Teknik Komputer', 2024, 'Flutter, UI/UX, Pitching, Project Management'),
('lecturer-bambang-user', 'Dr. H. Bambang Supriatna, M.T.', 'dosen@upi.edu', '123456', 'lecturer', null, null, null),
('student-aulia', 'Aulia Rahman', 'aulia@upi.edu', '123456', 'student', 'Pendidikan Ilmu Komputer', 2023, 'Leadership, Pitching'),
('student-siti', 'Siti Nurfadilah', 'siti@upi.edu', '123456', 'student', 'Desain Komunikasi Visual', 2023, 'UI/UX, Prototyping'),
('student-rizky', 'Rizky Maulana', 'rizky@upi.edu', '123456', 'student', 'Teknik Komputer', 2022, 'Backend, API, MySQL');

insert into public.competitions (id, title, organizer, category, level, deadline, description, registration_link, verification_status, interest_count) values
('comp-gemastik', 'GEMASTIK XVII', 'BPTI', 'Teknologi Informasi', 'Nasional', '20 Juni 2026', 'Kompetisi mahasiswa nasional bidang TIK.', 'https://gemastik.local', 'Terverifikasi', 98),
('comp-lidm', 'LIDM 2026', 'Puspresnas', 'Inovasi Digital Pendidikan', 'Nasional', '28 Juni 2026', 'Lomba inovasi digital pendidikan.', 'https://lidm.local', 'Terverifikasi', 74),
('comp-satria-data', 'Satria Data', 'Puspresnas', 'Data Science', 'Nasional', '3 Juli 2026', 'Kompetisi statistik dan data science.', 'https://satriadata.local', 'Terverifikasi', 62);

insert into public.lecturers (id, name, email, faculty, expertise, mentoring_status, mentoring_quota, current_mentoring_count, experiences, bio) values
('lecturer-bambang', 'Dr. H. Bambang Supriatna, M.T.', 'dosen@upi.edu', 'Fakultas Pendidikan Teknologi dan Kejuruan', 'Mobile Development, AI, Sistem Informasi', 'Tersedia', 5, 2, 'GEMASTIK XVI 2023 - Juara 1 Nasional, UI/UX Design Competition 2023 - Juara 2 Nasional', 'Pembimbing bidang software engineering dan sistem informasi.'),
('lecturer-nina', 'Dr. Nina Marasi, M.P.', 'nina@upi.edu', 'Fakultas Pendidikan Ekonomi dan Bisnis', 'Business, Manajemen, Kewirausahaan', 'Tersedia', 4, 1, 'Business Plan Competition 2024 - Best Innovation, KMI Expo 2023 - Finalis Nasional', 'Pembimbing business plan dan startup mahasiswa.'),
('lecturer-yudi', 'Dr. Yudi Sukmayadi, M.Pd.', 'yudi@upi.edu', 'Fakultas Ilmu Pendidikan', 'Pendidikan, Media Pembelajaran, TIK', 'Penuh', 4, 4, 'LIDM 2023 - Finalis Nasional, Inovasi Media Pembelajaran 2022 - Juara Favorit', 'Pembimbing media pembelajaran digital.');

insert into public.teams (id, competition_name, leader_id, team_name, description, required_roles, required_skills, deadline, matching_score, current_members, max_members) values
('team-nawasena', 'GEMASTIK - Pengembangan Perangkat Lunak', 'student-aulia', 'Nawasena Tech', 'Tim software development yang sedang membangun prototipe platform kampus pintar. Fokus tim adalah validasi ide, UI mobile, dan pitch deck untuk tahap final.', 'Mobile Developer, Backend Developer, Pitch Deck Specialist', 'Flutter, UI/UX, Backend, Pitching', '12 Juni 2026', 82, 3, 5),
('team-eduspark', 'LIDM - Inovasi Digital Pendidikan', 'student-candra', 'EduSpark Team', 'Tim inovasi pembelajaran digital yang mencari anggota untuk riset pengguna, desain antarmuka, dan produksi video demo.', 'UI/UX Designer, Researcher, Video Editor', 'UI/UX, Research, Video Editing', '18 Juni 2026', 68, 2, 4),
('team-biru-data', 'Satria Data', 'student-rizky', 'Biru Data Lab', 'Kelompok data analytics yang menyiapkan model prediksi dan dashboard insight untuk kompetisi Satria Data.', 'Data Analyst, Presenter', 'Python, Data Analysis, Presentation', '25 Juni 2026', 54, 2, 4);

insert into public.team_members (team_id, name, role_in_team) values
('team-nawasena', 'Aulia Rahman', 'Ketua Tim'),
('team-nawasena', 'Siti Nurfadilah', 'UI/UX Designer'),
('team-nawasena', 'Rizky Maulana', 'Backend Developer'),
('team-eduspark', 'Maya Larasati', 'Ketua Tim'),
('team-eduspark', 'Fikri Ramadhan', 'Researcher');

insert into public.join_requests (team_id, student_id, applied_role, message, matching_score, status) values
('team-eduspark', 'student-candra', 'UI/UX Designer', 'Saya tertarik membantu riset pengguna dan prototype.', 68, 'Menunggu');

insert into public.achievements (student_id, team_id, competition_name, award, category, level, year, certificate_link, verification_status, description) values
('student-candra', null, 'UI/UX Competition', 'Finalis', 'Desain Produk Digital', 'Nasional', '2025', '', 'Terverifikasi', 'Menyusun prototype mobile edukasi berbasis riset pengguna.'),
('student-candra', 'team-nawasena', 'GEMASTIK Software Development', 'Peserta', 'Pengembangan Perangkat Lunak', 'Nasional', '2025', '', 'Terverifikasi', 'Mengembangkan MVP aplikasi kolaborasi mahasiswa.');

alter table public.users enable row level security;
alter table public.competitions enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.join_requests enable row level security;
alter table public.lecturers enable row level security;
alter table public.mentorship_requests enable row level security;
alter table public.achievements enable row level security;

create policy "demo anon all users" on public.users for all to anon using (true) with check (true);
create policy "demo anon all competitions" on public.competitions for all to anon using (true) with check (true);
create policy "demo anon all teams" on public.teams for all to anon using (true) with check (true);
create policy "demo anon all team_members" on public.team_members for all to anon using (true) with check (true);
create policy "demo anon all join_requests" on public.join_requests for all to anon using (true) with check (true);
create policy "demo anon all lecturers" on public.lecturers for all to anon using (true) with check (true);
create policy "demo anon all mentorship_requests" on public.mentorship_requests for all to anon using (true) with check (true);
create policy "demo anon all achievements" on public.achievements for all to anon using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
