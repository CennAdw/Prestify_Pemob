import '../../core/services/api_service.dart';
import '../models/team_model.dart';
import 'repository_helpers.dart';

class TeamRepository {
  const TeamRepository({this.apiService = const ApiService()});

  final ApiService apiService;

  Future<List<TeamModel>> getTeams() async {
    final data = await apiService.get('teams/get_teams.php');
    return asMapList(data).map(TeamModel.fromJson).toList();
  }

  Future<TeamModel> getTeamDetail(String id) async {
    final data = await apiService.get(
      'teams/get_team_detail.php',
      queryParameters: {'id': id},
    );
    final map = asMap(data);
    final teamJson = <String, dynamic>{
      ...asMap(map['team'] ?? map),
      if (map['members'] != null) 'members': map['members'],
    };
    return TeamModel.fromJson(teamJson);
  }

  Future<void> createTeam({
    required String competitionId,
    required String leaderId,
    required String teamName,
    required String description,
    required String requiredSkills,
    required String requiredRoles,
  }) async {
    await apiService.post('teams/create_team.php', {
      'competition_id': competitionId,
      'leader_id': leaderId,
      'team_name': teamName,
      'description': description,
      'required_skills': requiredSkills,
      'required_roles': requiredRoles,
    });
  }

  Future<void> joinRequest({
    required String teamId,
    required String studentId,
    required String appliedRole,
    required String message,
  }) async {
    await apiService.post('teams/join_request.php', {
      'team_id': teamId,
      'student_id': studentId,
      'applied_role': appliedRole,
      'message': message,
    });
  }

  Future<void> updateJoinStatus({
    required String requestId,
    required String status,
  }) async {
    await apiService.post('teams/update_join_status.php', {
      'request_id': requestId,
      'status': status,
    });
  }
}
