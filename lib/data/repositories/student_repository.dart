import '../../core/services/api_service.dart';
import '../models/achievement_model.dart';
import '../models/student_model.dart';
import 'repository_helpers.dart';

class StudentRepository {
  const StudentRepository({this.apiService = const ApiService()});

  final ApiService apiService;

  Future<StudentModel> getProfile(String userId) async {
    final data = await apiService.get(
      'students/get_profile.php',
      queryParameters: {'user_id': userId},
    );
    return StudentModel.fromJson(asMap(data));
  }

  Future<List<AchievementModel>> getAchievements(String studentId) async {
    final data = await apiService.get(
      'achievements/get_achievements.php',
      queryParameters: {'student_id': studentId},
    );
    return asMapList(data).map(AchievementModel.fromJson).toList();
  }

  Future<void> createAchievement({
    required String studentId,
    required String competitionName,
    required String award,
    required String category,
    required String level,
    required String year,
    required String description,
  }) async {
    await apiService.post('achievements/create_achievement.php', {
      'student_id': studentId,
      'competition_name': competitionName,
      'award': award,
      'category': category,
      'level': level,
      'year': year,
      'description': description,
    });
  }
}
