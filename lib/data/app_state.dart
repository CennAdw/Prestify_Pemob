import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import 'dummy_data.dart';
import 'models/achievement_model.dart';
import 'models/competition_model.dart';
import 'models/lecturer_model.dart';
import 'models/team_model.dart';
import 'models/user_model.dart';
import 'repositories/auth_repository.dart';
import 'repositories/competition_repository.dart';
import 'repositories/lecturer_repository.dart';
import 'repositories/student_repository.dart';
import 'repositories/team_repository.dart';

class RecruitmentPost {
  const RecruitmentPost({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.skills,
    required this.competition,
    required this.createdLabel,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String skills;
  final String competition;
  final String createdLabel;
}

class ApplicationHistoryItem {
  const ApplicationHistoryItem({
    required this.id,
    required this.teamName,
    required this.competitionName,
    required this.appliedRole,
    required this.matchingScore,
    required this.status,
    required this.createdLabel,
  });

  final String id;
  final String teamName;
  final String competitionName;
  final String appliedRole;
  final int matchingScore;
  final String status;
  final String createdLabel;
}

class MentoringRequest {
  const MentoringRequest({
    required this.id,
    required this.teamName,
    required this.competitionName,
    required this.status,
  });

  final String id;
  final String teamName;
  final String competitionName;
  final String status;

  MentoringRequest copyWith({String? status}) {
    return MentoringRequest(
      id: id,
      teamName: teamName,
      competitionName: competitionName,
      status: status ?? this.status,
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.success,
    required this.route,
    required this.message,
    required this.usedFallback,
  });

  final bool success;
  final String route;
  final String message;
  final bool usedFallback;
}

class AppState extends ChangeNotifier {
  AppState({
    this.authRepository = const AuthRepository(),
    this.teamRepository = const TeamRepository(),
    this.competitionRepository = const CompetitionRepository(),
    this.lecturerRepository = const LecturerRepository(),
    this.studentRepository = const StudentRepository(),
    AuthService? authService,
  }) : authService = authService ?? AuthService();

  final AuthRepository authRepository;
  final TeamRepository teamRepository;
  final CompetitionRepository competitionRepository;
  final LecturerRepository lecturerRepository;
  final StudentRepository studentRepository;
  final AuthService authService;

  UserModel? currentUser;
  UserModel student = DummyData.student;
  UserModel lecturerUser = DummyData.lecturerUser;

  List<TeamModel> teams = List<TeamModel>.from(DummyData.teams);
  List<LecturerModel> lecturers = List<LecturerModel>.from(DummyData.lecturers);
  List<CompetitionModel> competitions = List<CompetitionModel>.from(
    DummyData.competitions,
  );
  List<AchievementModel> achievements = List<AchievementModel>.from(
    DummyData.achievements,
  );
  List<ApplicationHistoryItem> applicationHistory = const [];

  bool isAuthLoading = false;
  bool isTeamsLoading = false;
  bool isCompetitionsLoading = false;
  bool isLecturersLoading = false;
  bool isAchievementsLoading = false;
  bool isApplicationHistoryLoading = false;

  String? apiNotice;
  String? teamError;
  String? competitionError;
  String? lecturerError;
  String? achievementError;
  String? applicationHistoryError;

  final Set<String> _requestedTeamIds = {};
  final Set<String> _requestedLecturerIds = {};

  final List<RecruitmentPost> posts = [
    const RecruitmentPost(
      id: 'post-1',
      type: 'Mencari Anggota',
      title: 'Butuh Flutter dev untuk GEMASTIK',
      description:
          'MVP sudah ada, butuh anggota yang kuat di UI mobile dan integrasi state lokal.',
      skills: 'Flutter, UI/UX, Pitching',
      competition: 'GEMASTIK XVII',
      createdLabel: 'Hari ini',
    ),
    const RecruitmentPost(
      id: 'post-2',
      type: 'Mencari Tim',
      title: 'Cari tim LIDM bidang media pembelajaran',
      description:
          'Ingin bergabung dengan tim yang fokus pada riset pengguna dan prototipe edukasi.',
      skills: 'Research, UI/UX, Presentation',
      competition: 'LIDM 2026',
      createdLabel: 'Kemarin',
    ),
  ];

  final List<MentoringRequest> mentoringRequests = [
    const MentoringRequest(
      id: 'mentor-1',
      teamName: 'Nawasena Tech',
      competitionName: 'GEMASTIK',
      status: 'Menunggu',
    ),
    const MentoringRequest(
      id: 'mentor-2',
      teamName: 'EduSpark Team',
      competitionName: 'LIDM',
      status: 'Menunggu',
    ),
  ];

  TeamModel teamById(String id) {
    return teams.firstWhere(
      (team) => team.id == id,
      orElse: () => DummyData.teams.first,
    );
  }

  LecturerModel lecturerById(String id) {
    return lecturers.firstWhere(
      (lecturer) => lecturer.id == id,
      orElse: () => DummyData.lecturers.first,
    );
  }

  Future<LoginResult> login({
    required UserRole selectedRole,
    required String email,
    required String password,
  }) async {
    isAuthLoading = true;
    notifyListeners();

    try {
      final user = await authRepository.login(
        email: email,
        password: password,
        role: selectedRole,
      );
      _setCurrentUser(user);
      await authService.saveUser(user);
      apiNotice = null;
      return LoginResult(
        success: true,
        route: _routeForRole(user.role),
        message: 'Login Supabase berhasil.',
        usedFallback: false,
      );
    } catch (_) {
      final fallbackUser = _fallbackUserFor(selectedRole);
      _setCurrentUser(fallbackUser);
      await authService.saveUser(fallbackUser);
      apiNotice =
          'Supabase belum tersambung, aplikasi memakai data dummy sementara.';
      return LoginResult(
        success: true,
        route: _routeForRole(selectedRole),
        message: 'Supabase belum tersambung, masuk mode demo lokal.',
        usedFallback: true,
      );
    } finally {
      isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentDashboard() async {
    await Future.wait([
      loadTeams(),
      loadCompetitions(),
      loadAchievements(),
      loadApplicationHistory(),
    ]);
  }

  Future<void> loadTeams() async {
    isTeamsLoading = true;
    notifyListeners();
    try {
      final supabaseTeams = await teamRepository.getTeams();
      if (supabaseTeams.isNotEmpty) {
        teams = supabaseTeams.map(_restoreTeamRequestState).toList();
      }
      teamError = null;
    } catch (_) {
      teamError =
          'Tidak bisa mengambil data tim dari Supabase. Menampilkan fallback dummy.';
      teams = teams.isEmpty ? List<TeamModel>.from(DummyData.teams) : teams;
    } finally {
      isTeamsLoading = false;
      notifyListeners();
    }
  }

  Future<TeamModel> loadTeamDetail(String id) async {
    isTeamsLoading = true;
    notifyListeners();
    try {
      final detail = _restoreTeamRequestState(
        await teamRepository.getTeamDetail(id),
      );
      _upsertTeam(detail);
      teamError = null;
      return detail;
    } catch (_) {
      teamError =
          'Detail tim memakai data lokal karena Supabase tidak tersedia.';
      return teamById(id);
    } finally {
      isTeamsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCompetitions() async {
    isCompetitionsLoading = true;
    notifyListeners();
    try {
      final supabaseCompetitions = await competitionRepository
          .getCompetitions();
      if (supabaseCompetitions.isNotEmpty) competitions = supabaseCompetitions;
      competitionError = null;
    } catch (_) {
      competitionError =
          'Tidak bisa mengambil lomba dari Supabase. Menampilkan fallback dummy.';
      competitions = competitions.isEmpty
          ? List<CompetitionModel>.from(DummyData.competitions)
          : competitions;
    } finally {
      isCompetitionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLecturers() async {
    isLecturersLoading = true;
    notifyListeners();
    try {
      final supabaseLecturers = await lecturerRepository.getLecturers();
      if (supabaseLecturers.isNotEmpty) {
        lecturers = supabaseLecturers
            .map(_restoreLecturerRequestState)
            .toList();
      }
      lecturerError = null;
    } catch (_) {
      lecturerError =
          'Tidak bisa mengambil dosen dari Supabase. Menampilkan fallback dummy.';
      lecturers = lecturers.isEmpty
          ? List<LecturerModel>.from(DummyData.lecturers)
          : lecturers;
    } finally {
      isLecturersLoading = false;
      notifyListeners();
    }
  }

  Future<LecturerModel> loadLecturerDetail(String id) async {
    isLecturersLoading = true;
    notifyListeners();
    try {
      final detail = _restoreLecturerRequestState(
        await lecturerRepository.getLecturerDetail(id),
      );
      _upsertLecturer(detail);
      lecturerError = null;
      return detail;
    } catch (_) {
      lecturerError =
          'Detail dosen memakai data lokal karena Supabase tidak tersedia.';
      return lecturerById(id);
    } finally {
      isLecturersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAchievements() async {
    isAchievementsLoading = true;
    notifyListeners();
    try {
      final supabaseAchievements = await studentRepository.getAchievements(
        student.id,
      );
      if (supabaseAchievements.isNotEmpty) achievements = supabaseAchievements;
      achievementError = null;
    } catch (_) {
      achievementError =
          'Tidak bisa mengambil prestasi dari Supabase. Menampilkan fallback dummy.';
      achievements = achievements.isEmpty
          ? List<AchievementModel>.from(DummyData.achievements)
          : achievements;
    } finally {
      isAchievementsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadApplicationHistory() async {
    isApplicationHistoryLoading = true;
    notifyListeners();
    try {
      final requests = await teamRepository.getJoinRequests(student.id);
      applicationHistory = requests
          .map(
            (request) => ApplicationHistoryItem(
              id: request.id,
              teamName: request.teamName,
              competitionName: request.competitionName,
              appliedRole: request.appliedRole,
              matchingScore: request.matchingScore,
              status: request.status,
              createdLabel: 'Dari Supabase',
            ),
          )
          .toList();
      applicationHistoryError = null;
    } catch (_) {
      applicationHistoryError =
          'Riwayat ajuan memakai data lokal karena Supabase tidak tersedia.';
    } finally {
      isApplicationHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<String> requestJoinTeamApi(String teamId) async {
    final team = teamById(teamId);
    try {
      await teamRepository.joinRequest(
        teamId: teamId,
        studentId: student.id,
        appliedRole: 'Mobile Developer',
        message:
            'Saya ingin bergabung dan membantu pengembangan aplikasi serta pitching.',
      );
      requestJoinTeam(teamId);
      _addApplicationHistory(team, 'Menunggu', 'Dari Supabase');
      return 'Request bergabung berhasil dikirim ke Supabase.';
    } catch (_) {
      requestJoinTeam(teamId);
      _addApplicationHistory(team, 'Menunggu', 'Baru saja');
      return 'Supabase belum tersambung. Request disimpan lokal sementara.';
    }
  }

  Future<String> requestLecturerApi(String lecturerId) async {
    final teamId = teams.isNotEmpty ? teams.first.id : '1';
    try {
      await lecturerRepository.requestMentorship(
        teamId: teamId,
        lecturerId: lecturerId,
        proposalTitle: 'Proposal Mentoring UPI Connect+',
        proposalSummary:
            'Tim membutuhkan masukan untuk validasi ide, teknis MVP, dan strategi presentasi lomba.',
        proposalLink: '',
      );
      requestLecturer(lecturerId);
      return 'Request bimbingan berhasil dikirim ke Supabase.';
    } catch (_) {
      requestLecturer(lecturerId);
      return 'Supabase belum tersambung. Request bimbingan disimpan lokal sementara.';
    }
  }

  Future<String> publishRecruitmentPost({
    required String type,
    required String title,
    required String description,
    required String skills,
    required String competition,
  }) async {
    try {
      await teamRepository.createTeam(
        competitionName: competition,
        leaderId: student.id,
        teamName: title,
        description: description,
        requiredSkills: skills,
        requiredRoles: type,
      );
      addPost(
        type: type,
        title: title,
        description: description,
        skills: skills,
        competition: competition,
      );
      await loadTeams();
      return 'Postingan recruitment berhasil dipublikasikan ke Supabase.';
    } catch (_) {
      addPost(
        type: type,
        title: title,
        description: description,
        skills: skills,
        competition: competition,
      );
      return 'Supabase belum tersambung. Postingan disimpan lokal sementara.';
    }
  }

  Future<String> addAchievementApi(String title) async {
    try {
      await studentRepository.createAchievement(
        studentId: student.id,
        competitionName: title,
        award: 'Prestasi Baru',
        category: 'Demo',
        level: 'Kampus',
        year: '2026',
        description: 'Prestasi ditambahkan dari aplikasi UPI Connect+.',
      );
      addAchievement(title);
      return 'Prestasi berhasil ditambahkan ke Supabase.';
    } catch (_) {
      addAchievement(title);
      return 'Supabase belum tersambung. Prestasi disimpan lokal sementara.';
    }
  }

  Future<String> updateStudentSkills(List<String> skills) async {
    try {
      await studentRepository.updateSkills(
        studentId: student.id,
        skills: skills,
      );
      student = student.copyWith(skills: skills);
      return 'Skill berhasil diperbarui di Supabase.';
    } catch (_) {
      student = student.copyWith(skills: skills);
      return 'Supabase belum tersambung. Skill diperbarui lokal sementara.';
    } finally {
      notifyListeners();
    }
  }

  void requestJoinTeam(String teamId) {
    _requestedTeamIds.add(teamId);
    final index = teams.indexWhere((team) => team.id == teamId);
    if (index == -1) return;
    teams[index] = teams[index].copyWith(hasRequested: true);
    notifyListeners();
  }

  void requestLecturer(String lecturerId) {
    _requestedLecturerIds.add(lecturerId);
    final index = lecturers.indexWhere((lecturer) => lecturer.id == lecturerId);
    if (index == -1) return;
    lecturers[index] = lecturers[index].copyWith(hasRequested: true);
    notifyListeners();
  }

  void addPost({
    required String type,
    required String title,
    required String description,
    required String skills,
    required String competition,
  }) {
    posts.insert(
      0,
      RecruitmentPost(
        id: 'post-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        description: description,
        skills: skills,
        competition: competition,
        createdLabel: 'Baru saja',
      ),
    );
    notifyListeners();
  }

  void addAchievement(String title) {
    achievements.insert(
      0,
      AchievementModel(
        id: 'ach-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        subtitle: 'Prestasi ditambahkan dari demo lokal UPI Connect+',
        year: '2026',
      ),
    );
    notifyListeners();
  }

  void updateMentoringRequest(String requestId, String status) {
    final index = mentoringRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) return;
    mentoringRequests[index] = mentoringRequests[index].copyWith(
      status: status,
    );
    notifyListeners();
  }

  void _setCurrentUser(UserModel user) {
    currentUser = user;
    switch (user.role) {
      case UserRole.student:
        student = student.copyWith(
          id: user.id.isEmpty ? student.id : user.id,
          name: user.name.isEmpty ? student.name : user.name,
          email: user.email,
          skills: user.skills.isEmpty ? student.skills : user.skills,
          program: user.program ?? student.program,
          year: user.year ?? student.year,
        );
        break;
      case UserRole.lecturer:
        lecturerUser = user;
        break;
    }
  }

  UserModel _fallbackUserFor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return DummyData.student;
      case UserRole.lecturer:
        return DummyData.lecturerUser;
    }
  }

  String _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return '/student';
      case UserRole.lecturer:
        return '/lecturer';
    }
  }

  TeamModel _restoreTeamRequestState(TeamModel team) {
    return _requestedTeamIds.contains(team.id)
        ? team.copyWith(hasRequested: true)
        : team;
  }

  LecturerModel _restoreLecturerRequestState(LecturerModel lecturer) {
    return _requestedLecturerIds.contains(lecturer.id)
        ? lecturer.copyWith(hasRequested: true)
        : lecturer;
  }

  void _upsertTeam(TeamModel team) {
    final index = teams.indexWhere((item) => item.id == team.id);
    if (index == -1) {
      teams.insert(0, team);
    } else {
      teams[index] = team;
    }
  }

  void _upsertLecturer(LecturerModel lecturer) {
    final index = lecturers.indexWhere((item) => item.id == lecturer.id);
    if (index == -1) {
      lecturers.insert(0, lecturer);
    } else {
      lecturers[index] = lecturer;
    }
  }

  void _addApplicationHistory(
    TeamModel team,
    String status,
    String createdLabel,
  ) {
    final existingIndex = applicationHistory.indexWhere(
      (item) => item.id == team.id,
    );
    final item = ApplicationHistoryItem(
      id: team.id,
      teamName: team.name,
      competitionName: team.competitionName,
      appliedRole: 'Mobile Developer',
      matchingScore: team.matchingScore,
      status: status,
      createdLabel: createdLabel,
    );

    if (existingIndex == -1) {
      applicationHistory = [item, ...applicationHistory];
    } else {
      applicationHistory[existingIndex] = item;
    }
    notifyListeners();
  }
}
