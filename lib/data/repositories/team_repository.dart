import '../../core/services/supabase_service.dart';
import '../models/join_request_model.dart';
import '../models/team_model.dart';
import 'repository_helpers.dart';

class TeamRepository {
  const TeamRepository();

  Future<List<TeamModel>> getTeams() async {
    final data = await SupabaseService.client
        .from('teams')
        .select('*, team_members(name, role_in_team)')
        .order('created_at', ascending: false);

    return asMapList(data).map(TeamModel.fromJson).toList();
  }

  Future<TeamModel> getTeamDetail(String id) async {
    final data = await SupabaseService.client
        .from('teams')
        .select('*, team_members(name, role_in_team)')
        .eq('id', id)
        .limit(1);

    final teams = asMapList(data);
    if (teams.isEmpty) throw StateError('Tim tidak ditemukan.');
    return TeamModel.fromJson(teams.first);
  }

  Future<void> createTeam({
    required String competitionName,
    required String leaderId,
    required String teamName,
    required String description,
    required String requiredSkills,
    required String requiredRoles,
  }) async {
    await SupabaseService.client.from('teams').insert({
      'competition_name': competitionName,
      'leader_id': leaderId,
      'team_name': teamName,
      'description': description,
      'required_skills': requiredSkills,
      'required_roles': requiredRoles,
      'recruitment_status': 'Open Recruitment',
      'progress_status': 'Recruiting',
      'matching_score': 70,
      'current_members': 1,
      'max_members': 5,
      'deadline': 'Belum ditentukan',
    });
  }

  Future<void> joinRequest({
    required String teamId,
    required String studentId,
    required String appliedRole,
    required String message,
  }) async {
    await SupabaseService.client.from('join_requests').insert({
      'team_id': teamId,
      'student_id': studentId,
      'applied_role': appliedRole,
      'message': message,
      'matching_score': 82,
      'status': 'Menunggu',
    });
  }

  Future<List<JoinRequestModel>> getJoinRequests(String studentId) async {
    final data = await SupabaseService.client
        .from('join_requests')
        .select('*, teams(team_name, competition_name)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return asMapList(data).map(JoinRequestModel.fromJson).toList();
  }

  Future<void> updateJoinStatus({
    required String requestId,
    required String status,
  }) async {
    await SupabaseService.client
        .from('join_requests')
        .update({'status': status})
        .eq('id', requestId);
  }
}
