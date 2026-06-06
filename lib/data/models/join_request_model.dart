import 'model_helpers.dart';

class JoinRequestModel {
  const JoinRequestModel({
    required this.id,
    required this.teamId,
    required this.studentId,
    required this.message,
    required this.matchingScore,
    required this.status,
    this.teamName = '',
    this.competitionName = '',
    this.studentName = '',
    this.studentAvatarUrl = '',
    this.skills = const [],
    this.portfolioUrl,
  });

  final String id;
  final String teamId;
  final String studentId;
  final String message;
  final int matchingScore;
  final String status;
  final String teamName;
  final String competitionName;
  final String studentName;
  final String studentAvatarUrl;
  final List<String> skills;
  final String? portfolioUrl;

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    final team = json['teams'] is Map<String, dynamic>
        ? json['teams'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final student = json['users'] is Map<String, dynamic>
        ? json['users'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return JoinRequestModel(
      id: parseString(json['id']),
      teamId: parseString(json['team_id']),
      studentId: parseString(json['student_id']),
      message: parseString(json['message']),
      matchingScore: parseInt(json['matching_score']),
      status: parseString(json['status'], fallback: 'pending'),
      teamName: parseString(team['team_name'] ?? json['team_name']),
      competitionName: parseString(
        team['competition_name'] ?? json['competition_name'],
      ),
      studentName: parseString(student['name']),
      studentAvatarUrl: parseString(student['avatar_url']),
      skills: parseStringList(student['skills']),
      portfolioUrl: student['portfolio_url'] as String?,
    );
  }
}