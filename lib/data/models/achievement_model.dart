import 'model_helpers.dart';

class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.year,
  });

  final String id;
  final String title;
  final String subtitle;
  final String year;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final competitionName = parseString(
      json['competition_name'] ?? json['title'],
    );
    final award = parseString(json['award']);
    final level = parseString(json['level']);
    return AchievementModel(
      id: parseString(json['id']),
      title: award.isEmpty ? competitionName : '$award - $competitionName',
      subtitle: parseString(
        json['description'],
        fallback: [
          level,
          parseString(json['category']),
        ].where((item) => item.isNotEmpty).join(' - '),
      ),
      year: parseString(json['year'], fallback: '2026'),
    );
  }
}
