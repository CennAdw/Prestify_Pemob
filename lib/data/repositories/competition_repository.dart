import '../../core/services/api_service.dart';
import '../models/competition_model.dart';
import 'repository_helpers.dart';

class CompetitionRepository {
  const CompetitionRepository({this.apiService = const ApiService()});

  final ApiService apiService;

  Future<List<CompetitionModel>> getCompetitions() async {
    final data = await apiService.get('competitions/get_competitions.php');
    return asMapList(data).map(CompetitionModel.fromJson).toList();
  }

  Future<void> createCompetition({
    required String title,
    required String organizer,
    required String category,
    required String level,
    required String deadline,
    required String description,
    required String registrationLink,
  }) async {
    await apiService.post('competitions/create_competition.php', {
      'title': title,
      'organizer': organizer,
      'category': category,
      'level': level,
      'deadline': deadline,
      'description': description,
      'registration_link': registrationLink,
    });
  }

  Future<void> verifyCompetition({
    required String competitionId,
    required String verificationStatus,
  }) async {
    await apiService.post('competitions/verify_competition.php', {
      'competition_id': competitionId,
      'verification_status': verificationStatus,
    });
  }
}
