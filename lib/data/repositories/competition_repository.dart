import '../../core/services/supabase_service.dart';
import '../models/competition_model.dart';
import 'repository_helpers.dart';

class CompetitionRepository {
  const CompetitionRepository();

  Future<List<CompetitionModel>> getCompetitions() async {
    final data = await SupabaseService.client
        .from('teams')
        .select('competition_name, deadline')
        .order('created_at', ascending: false);

    final Map<String, Map<String, dynamic>> grouped = {};
    for (final row in asMapList(data)) {
      final name = row['competition_name'] as String? ?? '';
      if (name.isEmpty) continue;
      if (grouped.containsKey(name)) {
        grouped[name]!['interest_count'] =
            (grouped[name]!['interest_count'] as int) + 1;
      } else {
        grouped[name] = {
          'id': name.hashCode.toString(),
          'title': name,
          'category': 'Kompetisi',
          'deadline': row['deadline'] ?? 'Belum ditentukan',
          'status': 'Terverifikasi',
          'interest_count': 1,
        };
      }
    }

    return grouped.values.map(CompetitionModel.fromJson).toList();
  }
}