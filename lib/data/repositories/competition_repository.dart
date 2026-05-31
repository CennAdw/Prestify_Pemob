import '../../core/services/supabase_service.dart';
import '../models/competition_model.dart';
import 'repository_helpers.dart';

class CompetitionRepository {
  const CompetitionRepository();

  Future<List<CompetitionModel>> getCompetitions() async {
    final data = await SupabaseService.client
        .from('competitions')
        .select()
        .order('deadline', ascending: true);
    return asMapList(data).map(CompetitionModel.fromJson).toList();
  }
}
