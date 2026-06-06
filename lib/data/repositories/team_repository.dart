import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../models/join_request_model.dart';
import '../models/model_helpers.dart';
import '../models/team_model.dart';
import 'repository_helpers.dart';

class TeamRepository {
  const TeamRepository();

  int calculateMatchingScore(List<String> studentSkills, List<String> requiredSkills) {
    if (requiredSkills.isEmpty) return 0;
    
    final studentSkillSet = studentSkills
        .map((skill) => skill.toLowerCase().trim())
        .toSet();
    
    final matchedCount = requiredSkills
        .where((skill) => studentSkillSet.contains(skill.toLowerCase().trim()))
        .length;
    
    return ((matchedCount / requiredSkills.length) * 100).round();
  }

  Future<List<TeamModel>> getTeams() async {
    final data = await SupabaseService.client
        .from('teams')
        .select('*, team_members(student_id, name, role_in_team, users(avatar_url))')
        .order('created_at', ascending: false);

    return asMapList(data).map(TeamModel.fromJson).toList();
  }

  Future<TeamModel> getTeamDetail(String id) async {
    final data = await SupabaseService.client
        .from('teams')
        .select('*, team_members(student_id, name, role_in_team, users(avatar_url))')
        .eq('id', id)
        .limit(1);

    final teams = asMapList(data);
    if (teams.isEmpty) throw StateError('Tim tidak ditemukan.');
    return TeamModel.fromJson(teams.first);
  }

  Future<String> uploadTeamPoster({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final key = 'team-posters/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final bucket = SupabaseService.client.storage.from('team-posters');
    await bucket.uploadBinary(
      key,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return bucket.getPublicUrl(key);
  }

  Future<void> createTeam({
    required String competitionName,
    required String leaderId,
    required String teamName,
    required String description,
    required int maxMembers,
    required String requiredSkills,
    required String requiredRoles,
    String? posterUrl,
    String? notes,
  }) async {
    final insertResult = await SupabaseService.client.from('teams').insert({
      'competition_name': competitionName,
      'leader_id': leaderId,
      'team_name': teamName,
      'description': description,
      'required_skills': requiredSkills,
      'required_roles': requiredRoles,
      'max_members': maxMembers,
      'poster_url': posterUrl,
      'notes': notes,
      'recruitment_status': 'Open Recruitment',
      'progress_status': 'Recruiting',
      'matching_score': 0,
      'current_members': 1,
      'deadline': 'Belum ditentukan',
    }).select('id').limit(1).maybeSingle();

    final teamId = insertResult == null ? null : insertResult['id']?.toString();

    // ensure leader is also inserted into team_members so the leader appears as a member
    if (teamId != null && leaderId.isNotEmpty) {
      final leaderData = await SupabaseService.client
          .from('users')
          .select('name')
          .eq('id', leaderId)
          .limit(1)
          .maybeSingle();

      final leaderName = leaderData == null ? 'Leader' : (leaderData['name']?.toString() ?? 'Leader');

      await SupabaseService.client.from('team_members').insert({
        'team_id': teamId,
        'student_id': leaderId,
        'name': leaderName,
        'role_in_team': 'Leader',
      });
    }
  }

  Future<void> joinRequest({
    required String teamId,
    required String studentId,
    required String appliedRole,
    required String message,
    required List<String> studentSkills,
  }) async {
    final teamData = await SupabaseService.client
        .from('teams')
        .select('required_skills')
        .eq('id', teamId)
        .limit(1)
        .maybeSingle();

    final requiredSkills = teamData == null
        ? <String>[]
        : parseStringList(teamData['required_skills'] as String? ?? '');

    final matchingScore = calculateMatchingScore(studentSkills, requiredSkills);

    await SupabaseService.client.from('join_requests').insert({
      'team_id': teamId,
      'student_id': studentId,
      'applied_role': appliedRole,
      'message': message,
      'matching_score': matchingScore,
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

Future<List<JoinRequestModel>> getTeamJoinRequests(String teamId) async {
  final data = await SupabaseService.client
      .from('join_requests')
      .select('*, users(name, avatar_url, skills, portfolio_url), teams(team_name, competition_name)')
      .eq('team_id', teamId)
      .order('created_at', ascending: true);

  return asMapList(data).map(JoinRequestModel.fromJson).toList();
}

  Future<void> respondJoinRequest({
    required String requestId,
    required String status,
  }) async {
    final requestData = await SupabaseService.client
        .from('join_requests')
        .select('team_id, student_id')
        .eq('id', requestId)
        .limit(1)
        .maybeSingle();

    if (requestData == null) {
      throw StateError('Request bergabung tidak ditemukan.');
    }

    if (status == 'Diterima') {
      final studentData = await SupabaseService.client
          .from('users')
          .select('name')
          .eq('id', requestData['student_id'])
          .limit(1)
          .maybeSingle();

      final name = studentData == null
          ? 'Mahasiswa'
          : (studentData['name']?.toString() ?? 'Mahasiswa');

      await SupabaseService.client.from('team_members').insert({
        'team_id': requestData['team_id'],
        'student_id': requestData['student_id'],
        'name': name,
        'role_in_team': 'Anggota',
      });

      final teamData = await SupabaseService.client
          .from('teams')
          .select('current_members')
          .eq('id', requestData['team_id'])
          .limit(1)
          .maybeSingle();

      final currentMembers = teamData == null
          ? 0
          : (teamData['current_members'] is int
              ? teamData['current_members'] as int
              : int.tryParse(teamData['current_members']?.toString() ?? '') ?? 0);

      await SupabaseService.client.from('teams').update({
        'current_members': currentMembers + 1,
      }).eq('id', requestData['team_id']);
    }

    await SupabaseService.client
        .from('join_requests')
        .update({'status': status})
        .eq('id', requestId);
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