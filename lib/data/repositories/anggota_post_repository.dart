import '../../core/services/supabase_service.dart';
import '../models/anggota_post_model.dart';
import 'repository_helpers.dart';

class AnggotaPostRepository {
  const AnggotaPostRepository();

  Future<List<AnggotaPostModel>> getPosts() async {
    final data = await SupabaseService.client
        .from('anggota_post')
        .select('*, users(name, avatar_url, portfolio_url)')
        .eq('status', 'Aktif')
        .order('created_at', ascending: false);

    return asMapList(data).map(AnggotaPostModel.fromJson).toList();
  }

  Future<void> createPost({
    required String studentId,
    required String title,
    required String description,
    required String skills,
    required String competitionName,
    String? notes,
  }) async {
    await SupabaseService.client.from('anggota_post').insert({
      'student_id': studentId,
      'title': title,
      'description': description,
      'skills': skills,
      'competition_name': competitionName,
      'notes': notes ?? '',
      'status': 'Aktif',
    });
  }
}