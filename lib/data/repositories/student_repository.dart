import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../models/achievement_model.dart';
import '../models/user_model.dart';
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
    required String roleInCompetition,
    required String category,
    required String level,
    required String year,
    required String certificateLink,
    required String description,
  }) async {
    await SupabaseService.client.from('achievements').insert({
      'student_id': studentId,
      'competition_name': competitionName,
      'award': award,
      'role_in_competition': roleInCompetition,
      'category': category,
      'level': level,
      'year': year,
      'certificate_link': certificateLink,
      'verification_status': 'Menunggu Verifikasi',
      'description': description,
    });
  }

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String faculty,
    required String studyProgram,
    required int? batchYear,
    required List<String> skills,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'faculty': faculty,
      'study_program': studyProgram,
      'batch_year': batchYear,
      'skills': skills.join(', '),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    final data = await SupabaseService.client
        .from('users')
        .update(payload)
        .eq('id', userId)
        .select()
        .limit(1);
    final users = asMapList(data);
    if (users.isEmpty) throw StateError('Profil gagal diperbarui.');
    return UserModel.fromJson(users.first);
  }

  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final extension = _extensionFromFileName(fileName);
    final path =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$extension';
    final bucket = SupabaseService.client.storage.from('profile-photos');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return bucket.getPublicUrl(path);
  }

  String _extensionFromFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase();
    if (ext == 'png' || ext == 'webp' || ext == 'jpg' || ext == 'jpeg') {
      return ext;
    }
    return 'jpg';
  }
}
