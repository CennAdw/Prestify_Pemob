import '../../core/services/supabase_service.dart';
import '../models/achievement_model.dart';
import 'repository_helpers.dart';

class StudentRepository {
  const StudentRepository();

  Future<List<AchievementModel>> getAchievements(String studentId) async {
    final data = await SupabaseService.client
        .from('achievements')
        .select()
        .eq('student_id', studentId)
        .order('year', ascending: false);
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
    await SupabaseService.client.from('achievements').insert({
      'student_id': studentId,
      'competition_name': competitionName,
      'award': award,
      'category': category,
      'level': level,
      'year': year,
      'verification_status': 'Menunggu Verifikasi',
      'description': description,
    });
  }

  Future<void> updateSkills({
    required String studentId,
    required List<String> skills,
  }) async {
    await SupabaseService.client
        .from('users')
        .update({'skills': skills.join(', ')})
        .eq('id', studentId);
  }
}
