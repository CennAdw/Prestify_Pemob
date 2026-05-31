import 'model_helpers.dart';

class JoinRequestModel {
  const JoinRequestModel({
    required this.id,
    required this.teamId,
    required this.studentId,
    required this.appliedRole,
    required this.message,
    required this.matchingScore,
    required this.status,
    this.teamName = '',
    this.competitionName = '',
  });

  final String id;
  final String teamId;
  final String studentId;
  final String appliedRole;
  final String message;
  final int matchingScore;
  final String status;
  final String teamName;
  final String competitionName;

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    final team = json['teams'] is Map<String, dynamic>
        ? json['teams'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return JoinRequestModel(
      id: parseString(json['id']),
      teamId: parseString(json['team_id']),
      studentId: parseString(json['student_id']),
      appliedRole: parseString(json['applied_role']),
      message: parseString(json['message']),
      matchingScore: parseInt(json['matching_score']),
      status: parseString(json['status'], fallback: 'pending'),
      teamName: parseString(team['team_name'] ?? json['team_name']),
      competitionName: parseString(
        team['competition_name'] ?? json['competition_name'],
      ),
    );
  }
}
