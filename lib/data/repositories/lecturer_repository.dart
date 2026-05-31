import '../../core/services/api_service.dart';
import '../models/lecturer_model.dart';
import 'repository_helpers.dart';

class LecturerRepository {
  const LecturerRepository({this.apiService = const ApiService()});

  final ApiService apiService;

  Future<List<LecturerModel>> getLecturers() async {
    final data = await apiService.get('lecturers/get_lecturers.php');
    return asMapList(data).map(LecturerModel.fromJson).toList();
  }

  Future<LecturerModel> getLecturerDetail(String id) async {
    final data = await apiService.get(
      'lecturers/get_lecturer_detail.php',
      queryParameters: {'id': id},
    );
    return LecturerModel.fromJson(asMap(data));
  }

  Future<void> requestMentorship({
    required String teamId,
    required String lecturerId,
    required String proposalTitle,
    required String proposalSummary,
    required String proposalLink,
  }) async {
    await apiService.post('lecturers/request_mentorship.php', {
      'team_id': teamId,
      'lecturer_id': lecturerId,
      'proposal_title': proposalTitle,
      'proposal_summary': proposalSummary,
      'proposal_link': proposalLink,
    });
  }
}
