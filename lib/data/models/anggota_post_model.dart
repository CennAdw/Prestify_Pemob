import 'model_helpers.dart';

class AnggotaPostModel {
  const AnggotaPostModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentAvatarUrl,
    required this.title,
    required this.description,
    required this.skills,
    required this.competitionName,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.portfolioUrl,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String studentAvatarUrl;
  final String title;
  final String description;
  final List<String> skills;
  final String competitionName;
  final String notes;
  final String status;
  final String createdAt;
  final String? portfolioUrl;

  factory AnggotaPostModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] is Map<String, dynamic>
        ? json['users'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AnggotaPostModel(
      id: parseString(json['id']),
      studentId: parseString(json['student_id']),
      studentName: parseString(user['name'] ?? json['student_name']),
      studentAvatarUrl: parseString(user['avatar_url'] ?? json['student_avatar_url']),
      title: parseString(json['title']),
      description: parseString(json['description']),
      skills: parseStringList(json['skills']),
      competitionName: parseString(json['competition_name']),
      notes: parseString(json['notes']),
      status: parseString(json['status'], fallback: 'Aktif'),
      createdAt: parseString(json['created_at']),
      portfolioUrl: user['portfolio_url'] as String? ?? json['portfolio_url'] as String?,
    );
  }
}