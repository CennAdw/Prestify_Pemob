import '../../core/services/api_service.dart';
import '../models/competition_model.dart';
import 'repository_helpers.dart';

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalStudents,
    required this.totalTeams,
    required this.totalCompetitions,
    required this.totalLecturers,
    required this.categoryStats,
    required this.pendingCompetitions,
  });

  final int totalStudents;
  final int totalTeams;
  final int totalCompetitions;
  final int totalLecturers;
  final Map<String, int> categoryStats;
  final List<CompetitionModel> pendingCompetitions;
}

class AdminRepository {
  const AdminRepository({this.apiService = const ApiService()});

  final ApiService apiService;

  Future<AdminDashboardData> getDashboard() async {
    final data = asMap(await apiService.get('admin/dashboard.php'));
    final categoryStatsRaw = asMap(data['category_stats']);
    return AdminDashboardData(
      totalStudents:
          int.tryParse(data['total_students']?.toString() ?? '') ?? 0,
      totalTeams: int.tryParse(data['total_teams']?.toString() ?? '') ?? 0,
      totalCompetitions:
          int.tryParse(data['total_competitions']?.toString() ?? '') ?? 0,
      totalLecturers:
          int.tryParse(data['total_lecturers']?.toString() ?? '') ?? 0,
      categoryStats: categoryStatsRaw.map(
        (key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0),
      ),
      pendingCompetitions: asMapList(
        data['pending_competitions'],
      ).map(CompetitionModel.fromJson).toList(),
    );
  }
}
