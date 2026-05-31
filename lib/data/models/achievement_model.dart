import 'model_helpers.dart';

class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.competitionName,
    required this.award,
    required this.roleInCompetition,
    required this.category,
    required this.level,
    required this.year,
    required this.certificateLink,
    required this.description,
  });

  final String id;
  final String competitionName;
  final String award;
  final String roleInCompetition;
  final String category;
  final String level;
  final String year;
  final String certificateLink;
  final String description;

  String get title =>
      award.isEmpty ? competitionName : '$award - $competitionName';

  String get subtitle {
    return [
      if (roleInCompetition.isNotEmpty) 'Sebagai $roleInCompetition',
      if (category.isNotEmpty) category,
      if (level.isNotEmpty) level,
      if (description.isNotEmpty) description,
    ].join(' - ');
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final competitionName = parseString(
      json['competition_name'] ?? json['title'],
    );
    final award = parseString(json['award']);
    return AchievementModel(
      id: parseString(json['id']),
      competitionName: competitionName,
      award: award,
      roleInCompetition: parseString(json['role_in_competition']),
      category: parseString(json['category']),
      level: parseString(json['level']),
      year: parseString(json['year'], fallback: DateTime.now().year.toString()),
      certificateLink: parseString(json['certificate_link']),
      description: parseString(json['description']),
    );
  }
}
