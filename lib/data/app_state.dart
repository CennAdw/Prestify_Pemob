import 'package:flutter/foundation.dart';

import 'models/achievement_model.dart';
import 'models/competition_model.dart';
import 'models/lecturer_model.dart';
import 'models/mentorship_request_model.dart';
import 'models/team_model.dart';
import 'models/user_model.dart';
import 'repositories/auth_repository.dart';
import 'repositories/competition_repository.dart';
import 'repositories/lecturer_repository.dart';
import 'repositories/student_repository.dart';
import 'repositories/team_repository.dart';

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
    required this.proposalTitle,
    required this.proposalSummary,
    required this.status,
  });

  final String id;
  final String teamName;
  final String competitionName;
  final String proposalTitle;
  final String proposalSummary;
  final String status;

  MentoringRequest copyWith({String? status}) {
    return MentoringRequest(
      id: id,
      teamName: teamName,
      competitionName: competitionName,
      proposalTitle: proposalTitle,
      proposalSummary: proposalSummary,
      status: status ?? this.status,
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.success,
    required this.route,
    required this.message,
  });

  final bool success;
  final String route;
  final String message;
}

class AppState extends ChangeNotifier {
  AppState({
    this.authRepository = const AuthRepository(),
    this.teamRepository = const TeamRepository(),
    this.competitionRepository = const CompetitionRepository(),
    this.lecturerRepository = const LecturerRepository(),
    this.studentRepository = const StudentRepository(),
  });

  final AuthRepository authRepository;
  final TeamRepository teamRepository;
  final CompetitionRepository competitionRepository;
  final LecturerRepository lecturerRepository;
  final StudentRepository studentRepository;

  static const _emptyStudent = UserModel(
    id: '',
    name: '',
    email: '',
    role: UserRole.student,
    program: '-',
    year: null,
    skills: [],
  );

  static const _emptyLecturerUser = UserModel(
    id: '',
    name: '',
    email: '',
    role: UserRole.lecturer,
  );

  static const _emptyTeam = TeamModel(
    id: '',
    name: 'Data tim tidak tersedia',
    competitionName: '-',
    description: 'Data tim belum berhasil dimuat dari Supabase.',
    requiredSkills: [],
    currentMembers: 0,
    maxMembers: 0,
    deadline: '-',
    matchingScore: 0,
    status: 'Tidak tersedia',
    members: [],
  );

  static const _emptyLecturer = LecturerModel(
    id: '',
    name: 'Data dosen tidak tersedia',
    faculty: '-',
    expertise: [],
    status: 'Tidak tersedia',
    currentQuota: 0,
    maxQuota: 0,
    experiences: [],
  );

  UserModel? currentUser;
  UserModel student = _emptyStudent;
  UserModel lecturerUser = _emptyLecturerUser;

  List<TeamModel> teams = [];
  List<LecturerModel> lecturers = [];
  List<CompetitionModel> competitions = [];
  List<AchievementModel> achievements = [];
  List<ApplicationHistoryItem> applicationHistory = [];
  List<MentoringRequest> mentoringRequests = [];

  bool isAuthLoading = false;
  bool isTeamsLoading = false;
  bool isCompetitionsLoading = false;
  bool isLecturersLoading = false;
  bool isAchievementsLoading = false;
  bool isApplicationHistoryLoading = false;
  bool isMentoringRequestsLoading = false;

  String? apiNotice;
  String? teamError;
  String? competitionError;
  String? lecturerError;
  String? achievementError;
  String? applicationHistoryError;
  String? mentoringRequestError;

  final Set<String> _requestedTeamIds = {};
  final Set<String> _requestedLecturerIds = {};

  TeamModel teamById(String id) {
    return teams.firstWhere((team) => team.id == id, orElse: () => _emptyTeam);
  }

  LecturerModel lecturerById(String id) {
    return lecturers.firstWhere(
      (lecturer) => lecturer.id == id,
      orElse: () => _emptyLecturer,
    );
  }

  Future<LoginResult> signInWithGoogle() async {
    isAuthLoading = true;
    notifyListeners();

    try {
      final launched = await authRepository.signInWithGoogle();
      return LoginResult(
        success: launched,
        route: '',
        message: launched
            ? 'Selesaikan login di halaman Google.'
            : 'Browser login Google gagal dibuka.',
      );
    } catch (error, stackTrace) {
      _logSupabaseError('signInWithGoogle', error, stackTrace);
      apiNotice = 'Login gagal: $error';
      return LoginResult(
        success: false,
        route: '',
        message: 'Login gagal: $error',
      );
    } finally {
      isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<LoginResult> completeGoogleLogin() async {
    isAuthLoading = true;
    notifyListeners();

    try {
      final user = await authRepository.completeGoogleLogin();
      _setCurrentUser(user);
      apiNotice = null;
      return LoginResult(
        success: true,
        route: _routeForRole(user.role),
        message: 'Login Google berhasil.',
      );
    } catch (error, stackTrace) {
      _logSupabaseError('completeGoogleLogin', error, stackTrace);
      apiNotice = 'Login Google gagal: $error';
      return LoginResult(
        success: false,
        route: '',
        message: 'Login Google gagal: $error',
      );
    } finally {
      isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await authRepository.signOut();
    } catch (error, stackTrace) {
      _logSupabaseError('signOut', error, stackTrace);
    } finally {
      currentUser = null;
      student = _emptyStudent;
      lecturerUser = _emptyLecturerUser;
      teams = [];
      lecturers = [];
      competitions = [];
      achievements = [];
      applicationHistory = [];
      mentoringRequests = [];
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
      teams = supabaseTeams.map(_restoreTeamRequestState).toList();
      teamError = null;
    } catch (error, stackTrace) {
      _logSupabaseError('loadTeams', error, stackTrace);
      teamError = 'Gagal mengambil data tim dari Supabase: $error';
      teams = [];
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
    } catch (error, stackTrace) {
      _logSupabaseError('loadTeamDetail', error, stackTrace);
      teamError = 'Gagal mengambil detail tim dari Supabase: $error';
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
      competitions = await competitionRepository.getCompetitions();
      competitionError = null;
    } catch (error, stackTrace) {
      _logSupabaseError('loadCompetitions', error, stackTrace);
      competitionError = 'Gagal mengambil lomba dari Supabase: $error';
      competitions = [];
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
      lecturers = supabaseLecturers.map(_restoreLecturerRequestState).toList();
      lecturerError = null;
    } catch (error, stackTrace) {
      _logSupabaseError('loadLecturers', error, stackTrace);
      lecturerError = 'Gagal mengambil data dosen dari Supabase: $error';
      lecturers = [];
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
    } catch (error, stackTrace) {
      _logSupabaseError('loadLecturerDetail', error, stackTrace);
      lecturerError = 'Gagal mengambil detail dosen dari Supabase: $error';
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
      achievements = await studentRepository.getAchievements(student.id);
      achievementError = null;
    } catch (error, stackTrace) {
      _logSupabaseError('loadAchievements', error, stackTrace);
      achievementError = 'Gagal mengambil prestasi dari Supabase: $error';
      achievements = [];
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
    } catch (error, stackTrace) {
      _logSupabaseError('loadApplicationHistory', error, stackTrace);
      applicationHistoryError =
          'Gagal mengambil riwayat ajuan dari Supabase: $error';
      applicationHistory = [];
    } finally {
      isApplicationHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMentoringRequests() async {
    isMentoringRequestsLoading = true;
    notifyListeners();
    try {
      final requests = await lecturerRepository.getMentorshipRequests(
        lecturerUser.id,
      );
      mentoringRequests = requests.map(_mapMentoringRequest).toList();
      mentoringRequestError = null;
    } catch (error, stackTrace) {
      _logSupabaseError('loadMentoringRequests', error, stackTrace);
      mentoringRequestError =
          'Gagal mengambil request bimbingan dari Supabase: $error';
      mentoringRequests = [];
    } finally {
      isMentoringRequestsLoading = false;
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
        matchingScore: team.matchingScore,
      );
      requestJoinTeam(teamId);
      _addApplicationHistory(team, 'Menunggu', 'Dari Supabase');
      return 'Request bergabung berhasil dikirim.';
    } catch (error, stackTrace) {
      _logSupabaseError('requestJoinTeamApi', error, stackTrace);
      return 'Gagal mengirim request bergabung: $error';
    }
  }

  Future<String> requestLecturerApi(String lecturerId) async {
    final ownedTeams = teams.where((team) => team.leaderId == student.id);
    final teamId = ownedTeams.isNotEmpty ? ownedTeams.first.id : '';
    if (teamId.isEmpty) {
      const message =
          'Gagal mengirim request bimbingan: buat tim terlebih dahulu agar request dapat dikirim oleh ketua tim.';
      debugPrint('[Supabase][requestLecturerApi] $message');
      return message;
    }

    try {
      await lecturerRepository.requestMentorship(
        teamId: teamId,
        lecturerId: lecturerId,
        proposalTitle: 'Proposal Mentoring Prestify',
        proposalSummary:
            'Tim membutuhkan masukan untuk validasi ide, teknis MVP, dan strategi presentasi lomba.',
        proposalLink: '',
      );
      requestLecturer(lecturerId);
      return 'Request bimbingan berhasil dikirim.';
    } catch (error, stackTrace) {
      _logSupabaseError('requestLecturerApi', error, stackTrace);
      return 'Gagal mengirim request bimbingan: $error';
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
      await loadTeams();
      return 'Postingan recruitment berhasil dipublikasikan.';
    } catch (error, stackTrace) {
      _logSupabaseError('publishRecruitmentPost', error, stackTrace);
      return 'Gagal mempublikasikan postingan: $error';
    }
  }

  Future<String> createAchievementApi({
    required String competitionName,
    required String award,
    required String roleInCompetition,
    required String category,
    required String level,
    required String year,
    required String certificateLink,
    required String description,
  }) async {
    try {
      await studentRepository.createAchievement(
        studentId: student.id,
        competitionName: competitionName,
        award: award,
        roleInCompetition: roleInCompetition,
        category: category,
        level: level,
        year: year,
        certificateLink: certificateLink,
        description: description,
      );
      await loadAchievements();
      return 'Prestasi berhasil ditambahkan.';
    } catch (error, stackTrace) {
      _logSupabaseError('createAchievementApi', error, stackTrace);
      return 'Gagal menambahkan prestasi: $error';
    }
  }

  Future<String> updateStudentSkills(List<String> skills) async {
    try {
      student = await studentRepository.updateProfile(
        userId: student.id,
        name: student.name,
        studyProgram: student.program ?? '',
        batchYear: student.year,
        skills: skills,
      );
      notifyListeners();
      return 'Skill berhasil diperbarui.';
    } catch (error, stackTrace) {
      _logSupabaseError('updateStudentSkills', error, stackTrace);
      return 'Gagal memperbarui skill: $error';
    }
  }

  Future<String> updateStudentProfile({
    required String name,
    required String studyProgram,
    required int? batchYear,
    required List<String> skills,
  }) async {
    try {
      student = await studentRepository.updateProfile(
        userId: student.id,
        name: name,
        studyProgram: studyProgram,
        batchYear: batchYear,
        skills: skills,
      );
      notifyListeners();
      return 'Profil berhasil diperbarui.';
    } catch (error, stackTrace) {
      _logSupabaseError('updateStudentProfile', error, stackTrace);
      return 'Gagal memperbarui profil: $error';
    }
  }

  Future<String> uploadStudentProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final avatarUrl = await studentRepository.uploadProfilePhoto(
        userId: student.id,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      student = await studentRepository.updateProfile(
        userId: student.id,
        name: student.name,
        studyProgram: student.program ?? '',
        batchYear: student.year,
        skills: student.skills,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
      return 'Foto profil berhasil diperbarui.';
    } catch (error, stackTrace) {
      _logSupabaseError('uploadStudentProfilePhoto', error, stackTrace);
      return 'Gagal memperbarui foto profil: $error';
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

  Future<String> updateMentoringRequest(String requestId, String status) async {
    try {
      await lecturerRepository.updateMentorshipRequestStatus(
        requestId: requestId,
        status: status,
      );
      final index = mentoringRequests.indexWhere(
        (request) => request.id == requestId,
      );
      if (index != -1) {
        mentoringRequests[index] = mentoringRequests[index].copyWith(
          status: status,
        );
      }
      notifyListeners();
      return 'Status request berhasil diperbarui.';
    } catch (error, stackTrace) {
      _logSupabaseError('updateMentoringRequest', error, stackTrace);
      return 'Gagal memperbarui status request: $error';
    }
  }

  void _setCurrentUser(UserModel user) {
    currentUser = user;
    switch (user.role) {
      case UserRole.student:
        student = user.copyWith(
          name: user.name.isEmpty ? 'Mahasiswa' : user.name,
          program: user.program ?? '-',
        );
        break;
      case UserRole.lecturer:
        lecturerUser = user;
        break;
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

  MentoringRequest _mapMentoringRequest(MentorshipRequestModel request) {
    return MentoringRequest(
      id: request.id,
      teamName: request.teamName,
      competitionName: request.competitionName,
      proposalTitle: request.proposalTitle,
      proposalSummary: request.proposalSummary,
      status: request.status,
    );
  }

  void _logSupabaseError(String context, Object error, StackTrace stackTrace) {
    debugPrint('[Supabase][$context] $error');
    debugPrintStack(
      label: '[Supabase][$context] Stack trace',
      stackTrace: stackTrace,
    );
  }
}
