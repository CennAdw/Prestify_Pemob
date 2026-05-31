import '../../core/services/supabase_service.dart';
import '../models/lecturer_model.dart';
import 'repository_helpers.dart';

class LecturerRepository {
  const LecturerRepository();

  Future<List<LecturerModel>> getLecturers() async {
    final data = await SupabaseService.client
        .from('lecturers')
        .select()
        .order('id');
    return asMapList(data).map(LecturerModel.fromJson).toList();
  }

  Future<LecturerModel> getLecturerDetail(String id) async {
    final data = await SupabaseService.client
        .from('lecturers')
        .select()
        .eq('id', id)
        .limit(1);
    final lecturers = asMapList(data);
    if (lecturers.isEmpty) throw StateError('Dosen tidak ditemukan.');
    return LecturerModel.fromJson(lecturers.first);
  }

  Future<void> requestMentorship({
    required String teamId,
    required String lecturerId,
    required String proposalTitle,
    required String proposalSummary,
    required String proposalLink,
  }) async {
    await SupabaseService.client.from('mentorship_requests').insert({
      'team_id': teamId,
      'lecturer_id': lecturerId,
      'proposal_title': proposalTitle,
      'proposal_summary': proposalSummary,
      'proposal_link': proposalLink,
      'status': 'Menunggu',
    });
  }
}
