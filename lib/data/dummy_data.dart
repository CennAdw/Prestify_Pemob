import 'models/achievement_model.dart';
import 'models/competition_model.dart';
import 'models/lecturer_model.dart';
import 'models/team_model.dart';
import 'models/user_model.dart';

class DummyData {
  const DummyData._();

  static const student = UserModel(
    id: 'student-candra',
    name: 'Candra',
    email: 'candra@upi.edu',
    role: UserRole.student,
    program: 'Teknik Komputer',
    year: 2024,
    skills: ['Flutter', 'UI/UX', 'Pitching', 'Project Management'],
  );

  static const lecturerUser = UserModel(
    id: 'lecturer-demo',
    name: 'Dr. H. Bambang Supriatna, M.T.',
    email: 'dosen@upi.edu',
    role: UserRole.lecturer,
  );

  static const teams = [
    TeamModel(
      id: 'team-nawasena',
      name: 'Nawasena Tech',
      competitionName: 'GEMASTIK - Pengembangan Perangkat Lunak',
      description:
          'Tim software development yang sedang membangun prototipe platform kampus pintar. Fokus tim adalah validasi ide, UI mobile, dan pitch deck untuk tahap final.',
      requiredSkills: ['Flutter', 'UI/UX', 'Backend', 'Pitching'],
      currentMembers: 3,
      maxMembers: 5,
      deadline: '12 Juni 2026',
      matchingScore: 82,
      status: 'Open Recruitment',
      members: [
        TeamMember(name: 'Aulia Rahman', role: 'Ketua Tim'),
        TeamMember(name: 'Siti Nurfadilah', role: 'UI/UX Designer'),
        TeamMember(name: 'Rizky Maulana', role: 'Backend Developer'),
      ],
    ),
    TeamModel(
      id: 'team-eduspark',
      name: 'EduSpark Team',
      competitionName: 'LIDM - Inovasi Digital Pendidikan',
      description:
          'Tim inovasi pembelajaran digital yang mencari anggota untuk riset pengguna, desain antarmuka, dan produksi video demo.',
      requiredSkills: ['UI/UX', 'Research', 'Video Editing'],
      currentMembers: 2,
      maxMembers: 4,
      deadline: '18 Juni 2026',
      matchingScore: 68,
      status: 'Open Recruitment',
      members: [
        TeamMember(name: 'Maya Larasati', role: 'Ketua Tim'),
        TeamMember(name: 'Fikri Ramadhan', role: 'Researcher'),
      ],
    ),
    TeamModel(
      id: 'team-biru-data',
      name: 'Biru Data Lab',
      competitionName: 'Satria Data',
      description:
          'Kelompok data analytics yang menyiapkan model prediksi dan dashboard insight untuk kompetisi Satria Data.',
      requiredSkills: ['Python', 'Data Analysis', 'Presentation'],
      currentMembers: 2,
      maxMembers: 4,
      deadline: '25 Juni 2026',
      matchingScore: 54,
      status: 'Open Recruitment',
      members: [
        TeamMember(name: 'Dimas Arya', role: 'Data Analyst'),
        TeamMember(name: 'Rani Putri', role: 'Presenter'),
      ],
    ),
  ];

  static const lecturers = [
    LecturerModel(
      id: 'lecturer-bambang',
      name: 'Dr. H. Bambang Supriatna, M.T.',
      faculty: 'Fakultas Pendidikan Teknologi dan Kejuruan',
      expertise: ['Mobile Development', 'AI', 'Sistem Informasi'],
      status: 'Tersedia',
      currentQuota: 2,
      maxQuota: 5,
      experiences: [
        'GEMASTIK XVI 2023 - Juara 1 Nasional',
        'UI/UX Design Competition 2023 - Juara 2 Nasional',
      ],
    ),
    LecturerModel(
      id: 'lecturer-nina',
      name: 'Dr. Nina Marasi, M.P.',
      faculty: 'Fakultas Pendidikan Ekonomi dan Bisnis',
      expertise: ['Business', 'Manajemen', 'Kewirausahaan'],
      status: 'Tersedia',
      currentQuota: 1,
      maxQuota: 4,
      experiences: [
        'Business Plan Competition 2024 - Best Innovation',
        'KMI Expo 2023 - Finalis Nasional',
      ],
    ),
    LecturerModel(
      id: 'lecturer-yudi',
      name: 'Dr. Yudi Sukmayadi, M.Pd.',
      faculty: 'Fakultas Ilmu Pendidikan',
      expertise: ['Pendidikan', 'Media Pembelajaran', 'TIK'],
      status: 'Penuh',
      currentQuota: 4,
      maxQuota: 4,
      experiences: [
        'LIDM 2023 - Finalis Nasional',
        'Inovasi Media Pembelajaran 2022 - Juara Favorit',
      ],
    ),
  ];

  static const competitions = [
    CompetitionModel(
      id: 'comp-gemastik',
      name: 'GEMASTIK XVII',
      category: 'Teknologi Informasi',
      deadline: '20 Juni 2026',
      status: 'Terverifikasi',
      interestCount: 98,
    ),
    CompetitionModel(
      id: 'comp-lidm',
      name: 'LIDM 2026',
      category: 'Inovasi Digital Pendidikan',
      deadline: '28 Juni 2026',
      status: 'Menunggu Verifikasi',
      interestCount: 74,
    ),
    CompetitionModel(
      id: 'comp-satria-data',
      name: 'Satria Data',
      category: 'Data Science',
      deadline: '3 Juli 2026',
      status: 'Menunggu Verifikasi',
      interestCount: 62,
    ),
    CompetitionModel(
      id: 'comp-uiux',
      name: 'UI/UX Design Challenge',
      category: 'Desain Produk Digital',
      deadline: '16 Juni 2026',
      status: 'Terverifikasi',
      interestCount: 86,
    ),
  ];

  static const achievements = [
    AchievementModel(
      id: 'ach-uiux',
      title: 'Finalis UI/UX Competition',
      subtitle: 'Menyusun prototype mobile edukasi berbasis riset pengguna',
      year: '2025',
    ),
    AchievementModel(
      id: 'ach-gemastik',
      title: 'Peserta GEMASTIK Software Development',
      subtitle: 'Mengembangkan MVP aplikasi kolaborasi mahasiswa',
      year: '2025',
    ),
    AchievementModel(
      id: 'ach-umkm',
      title: 'Ketua Project Web UMKM',
      subtitle: 'Memimpin tim 4 orang untuk digitalisasi katalog produk',
      year: '2024',
    ),
  ];
}
