CREATE DATABASE IF NOT EXISTS upi_connect_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE upi_connect_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS achievements;
DROP TABLE IF EXISTS mentorship_requests;
DROP TABLE IF EXISTS join_requests;
DROP TABLE IF EXISTS team_members;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS competitions;
DROP TABLE IF EXISTS lecturers;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('student', 'lecturer', 'admin') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  nim VARCHAR(40) NOT NULL,
  faculty VARCHAR(150) NOT NULL,
  study_program VARCHAR(150) NOT NULL,
  batch_year INT NOT NULL,
  skills TEXT,
  interests TEXT,
  portfolio_link VARCHAR(255),
  bio TEXT,
  CONSTRAINT fk_students_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE lecturers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  nidn VARCHAR(40) NOT NULL,
  faculty VARCHAR(150) NOT NULL,
  expertise TEXT,
  mentoring_status ENUM('Tersedia', 'Penuh') DEFAULT 'Tersedia',
  mentoring_quota INT DEFAULT 5,
  current_mentoring_count INT DEFAULT 0,
  bio TEXT,
  CONSTRAINT fk_lecturers_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE competitions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(180) NOT NULL,
  organizer VARCHAR(160) NOT NULL,
  category VARCHAR(120) NOT NULL,
  level VARCHAR(80) NOT NULL,
  deadline DATE NOT NULL,
  description TEXT,
  registration_link VARCHAR(255),
  verification_status ENUM('Menunggu Verifikasi', 'Terverifikasi', 'Ditolak') DEFAULT 'Menunggu Verifikasi',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE teams (
  id INT AUTO_INCREMENT PRIMARY KEY,
  competition_id INT NOT NULL,
  leader_id INT NOT NULL,
  team_name VARCHAR(160) NOT NULL,
  description TEXT,
  required_roles TEXT,
  required_skills TEXT,
  recruitment_status ENUM('Open Recruitment', 'Closed') DEFAULT 'Open Recruitment',
  progress_status VARCHAR(80) DEFAULT 'Recruiting',
  mentor_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_teams_competition
    FOREIGN KEY (competition_id) REFERENCES competitions(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_teams_leader
    FOREIGN KEY (leader_id) REFERENCES students(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_teams_mentor
    FOREIGN KEY (mentor_id) REFERENCES lecturers(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE team_members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  team_id INT NOT NULL,
  student_id INT NOT NULL,
  role_in_team VARCHAR(120) NOT NULL,
  status ENUM('active', 'pending', 'left') DEFAULT 'active',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_team_members_team
    FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_team_members_student
    FOREIGN KEY (student_id) REFERENCES students(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE join_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  team_id INT NOT NULL,
  student_id INT NOT NULL,
  applied_role VARCHAR(120) NOT NULL,
  message TEXT,
  matching_score INT DEFAULT 0,
  status ENUM('pending', 'accepted', 'rejected', 'Menunggu', 'Diterima', 'Ditolak') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_join_requests_team
    FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_join_requests_student
    FOREIGN KEY (student_id) REFERENCES students(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mentorship_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  team_id INT NOT NULL,
  lecturer_id INT NOT NULL,
  proposal_title VARCHAR(180) NOT NULL,
  proposal_summary TEXT,
  proposal_link VARCHAR(255),
  status ENUM('pending', 'accepted', 'rejected', 'Menunggu', 'Diterima', 'Ditolak') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mentorship_requests_team
    FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_mentorship_requests_lecturer
    FOREIGN KEY (lecturer_id) REFERENCES lecturers(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE achievements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  team_id INT NULL,
  competition_name VARCHAR(180) NOT NULL,
  award VARCHAR(180) NOT NULL,
  category VARCHAR(120),
  level VARCHAR(80),
  year VARCHAR(10),
  certificate_link VARCHAR(255),
  verification_status ENUM('Menunggu Verifikasi', 'Terverifikasi', 'Ditolak') DEFAULT 'Menunggu Verifikasi',
  description TEXT,
  CONSTRAINT fk_achievements_student
    FOREIGN KEY (student_id) REFERENCES students(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_achievements_team
    FOREIGN KEY (team_id) REFERENCES teams(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- Password semua akun dummy adalah 123456.
-- Nilai di bawah adalah SHA-256 untuk MVP lokal; register.php tetap memakai password_hash().
SET @dummy_password = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';

INSERT INTO users (id, name, email, password, role) VALUES
(1, 'Candra Pratama', 'candra@upi.edu', @dummy_password, 'student'),
(2, 'Dr. H. Bambang Supriatna, M.T.', 'dosen@upi.edu', @dummy_password, 'lecturer'),
(3, 'Admin Rumah Prestasi', 'admin@upi.edu', @dummy_password, 'admin'),
(4, 'Dr. Nina Marasi, M.P.', 'nina@upi.edu', @dummy_password, 'lecturer'),
(5, 'Dr. Yudi Sukmayadi, M.Pd.', 'yudi@upi.edu', @dummy_password, 'lecturer'),
(6, 'Aulia Rahman', 'aulia@upi.edu', @dummy_password, 'student'),
(7, 'Siti Nurfadilah', 'siti@upi.edu', @dummy_password, 'student'),
(8, 'Rizky Maulana', 'rizky@upi.edu', @dummy_password, 'student'),
(9, 'Maya Larasati', 'maya@upi.edu', @dummy_password, 'student'),
(10, 'Fikri Ramadhan', 'fikri@upi.edu', @dummy_password, 'student'),
(11, 'Dimas Arya', 'dimas@upi.edu', @dummy_password, 'student'),
(12, 'Rani Putri', 'rani@upi.edu', @dummy_password, 'student');

INSERT INTO students (id, user_id, nim, faculty, study_program, batch_year, skills, interests, portfolio_link, bio) VALUES
(1, 1, '2401001', 'Fakultas Pendidikan Teknologi dan Kejuruan', 'Teknik Komputer', 2024, 'Flutter, UI/UX, Pitching, Project Management', 'Mobile App, Startup, Product Design', 'https://portfolio.local/candra', 'Mahasiswa Teknik Komputer yang tertarik membangun produk digital untuk kompetisi.'),
(2, 6, '2302001', 'Fakultas Pendidikan Teknologi dan Kejuruan', 'Pendidikan Ilmu Komputer', 2023, 'Leadership, Product Management, Pitching', 'GEMASTIK, Software Development', '', 'Ketua tim dengan pengalaman kompetisi software.'),
(3, 7, '2302002', 'Fakultas Seni dan Desain', 'Desain Komunikasi Visual', 2023, 'UI/UX, Design System, Prototyping', 'UI/UX Competition, LIDM', '', 'Designer yang kuat dalam riset pengguna dan prototype.'),
(4, 8, '2203001', 'Fakultas Pendidikan Teknologi dan Kejuruan', 'Teknik Komputer', 2022, 'Backend, Laravel, MySQL, API', 'Software Development', '', 'Backend developer untuk integrasi API dan database.'),
(5, 9, '2304001', 'Fakultas Ilmu Pendidikan', 'Teknologi Pendidikan', 2023, 'Research, Education, Writing', 'LIDM, Media Pembelajaran', '', 'Researcher untuk inovasi pembelajaran digital.'),
(6, 10, '2304002', 'Fakultas Ilmu Pendidikan', 'Teknologi Pendidikan', 2023, 'Video Editing, Storyboard, Presentation', 'LIDM, Video Demo', '', 'Editor video dan presenter.'),
(7, 11, '2205001', 'Fakultas Pendidikan Matematika dan IPA', 'Ilmu Komputer', 2022, 'Python, Data Analysis, Machine Learning', 'Satria Data', '', 'Data analyst untuk kompetisi data nasional.'),
(8, 12, '2205002', 'Fakultas Pendidikan Matematika dan IPA', 'Statistika', 2022, 'Presentation, Statistics, Dashboard', 'Satria Data', '', 'Presenter dan analis statistik.');

INSERT INTO lecturers (id, user_id, nidn, faculty, expertise, mentoring_status, mentoring_quota, current_mentoring_count, bio) VALUES
(1, 2, '0011223344', 'Fakultas Pendidikan Teknologi dan Kejuruan', 'Mobile Development, AI, Sistem Informasi', 'Tersedia', 5, 2, 'Dosen pembimbing bidang rekayasa perangkat lunak dan sistem informasi.'),
(2, 4, '0055667788', 'Fakultas Pendidikan Ekonomi dan Bisnis', 'Business, Manajemen, Kewirausahaan', 'Tersedia', 4, 1, 'Dosen pembimbing business plan, startup, dan kewirausahaan mahasiswa.'),
(3, 5, '0099887766', 'Fakultas Ilmu Pendidikan', 'Pendidikan, Media Pembelajaran, TIK', 'Penuh', 4, 4, 'Dosen pembimbing inovasi media pembelajaran dan teknologi pendidikan.');

INSERT INTO competitions (id, title, organizer, category, level, deadline, description, registration_link, verification_status) VALUES
(1, 'GEMASTIK XVII', 'Balai Pengembangan Talenta Indonesia', 'Teknologi Informasi', 'Nasional', '2026-06-20', 'Kompetisi mahasiswa nasional bidang TIK.', 'https://gemastik.local', 'Terverifikasi'),
(2, 'LIDM 2026', 'Puspresnas', 'Inovasi Digital Pendidikan', 'Nasional', '2026-06-28', 'Lomba inovasi pembelajaran dan teknologi digital.', 'https://lidm.local', 'Menunggu Verifikasi'),
(3, 'Satria Data', 'Puspresnas', 'Data Science', 'Nasional', '2026-07-03', 'Kompetisi statistik, data science, dan big data.', 'https://satriadata.local', 'Menunggu Verifikasi'),
(4, 'UI/UX Design Challenge', 'Digital Creative Association', 'Desain Produk Digital', 'Nasional', '2026-06-16', 'Kompetisi desain pengalaman pengguna berbasis studi kasus.', 'https://uiux.local', 'Terverifikasi'),
(5, 'Business Plan Competition', 'UPI Entrepreneur Center', 'Kewirausahaan', 'Kampus', '2026-07-15', 'Kompetisi rencana bisnis mahasiswa UPI.', 'https://business.local', 'Terverifikasi');

INSERT INTO teams (id, competition_id, leader_id, team_name, description, required_roles, required_skills, recruitment_status, progress_status, mentor_id) VALUES
(1, 1, 2, 'Nawasena Tech', 'Tim software development yang sedang membangun prototipe platform kampus pintar. Fokus tim adalah validasi ide, UI mobile, dan pitch deck untuk tahap final.', 'Mobile Developer, Backend Developer, Pitch Deck Specialist', 'Flutter, UI/UX, Backend, Pitching', 'Open Recruitment', 'Recruiting', 1),
(2, 2, 5, 'EduSpark Team', 'Tim inovasi pembelajaran digital yang mencari anggota untuk riset pengguna, desain antarmuka, dan produksi video demo.', 'UI/UX Designer, Researcher, Video Editor', 'UI/UX, Research, Video Editing', 'Open Recruitment', 'Recruiting', 3),
(3, 3, 7, 'Biru Data Lab', 'Kelompok data analytics yang menyiapkan model prediksi dan dashboard insight untuk kompetisi Satria Data.', 'Data Analyst, Presenter', 'Python, Data Analysis, Presentation', 'Open Recruitment', 'Recruiting', NULL);

INSERT INTO team_members (team_id, student_id, role_in_team, status) VALUES
(1, 2, 'Ketua Tim', 'active'),
(1, 3, 'UI/UX Designer', 'active'),
(1, 4, 'Backend Developer', 'active'),
(2, 5, 'Ketua Tim', 'active'),
(2, 6, 'Researcher', 'active'),
(3, 7, 'Data Analyst', 'active'),
(3, 8, 'Presenter', 'active');

INSERT INTO join_requests (team_id, student_id, applied_role, message, matching_score, status) VALUES
(1, 1, 'Mobile Developer', 'Saya bisa membantu Flutter dan pitch deck.', 82, 'pending'),
(2, 1, 'UI/UX Designer', 'Saya tertarik membantu desain prototype edukasi.', 68, 'pending');

INSERT INTO mentorship_requests (team_id, lecturer_id, proposal_title, proposal_summary, proposal_link, status) VALUES
(1, 1, 'Proposal Nawasena Tech - GEMASTIK', 'Platform kolaborasi mahasiswa untuk pembentukan tim lomba.', '', 'pending'),
(2, 3, 'Proposal EduSpark Team - LIDM', 'Inovasi media pembelajaran digital berbasis kebutuhan kelas.', '', 'pending');

INSERT INTO achievements (student_id, team_id, competition_name, award, category, level, year, certificate_link, verification_status, description) VALUES
(1, NULL, 'UI/UX Competition', 'Finalis', 'Desain Produk Digital', 'Nasional', '2025', '', 'Terverifikasi', 'Menyusun prototype mobile edukasi berbasis riset pengguna.'),
(1, 1, 'GEMASTIK Software Development', 'Peserta', 'Pengembangan Perangkat Lunak', 'Nasional', '2025', '', 'Terverifikasi', 'Mengembangkan MVP aplikasi kolaborasi mahasiswa.'),
(1, NULL, 'Project Web UMKM', 'Ketua Project', 'Pengabdian Digital', 'Kampus', '2024', '', 'Terverifikasi', 'Memimpin tim 4 orang untuk digitalisasi katalog produk UMKM.');
