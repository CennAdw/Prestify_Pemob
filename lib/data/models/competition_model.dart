import 'model_helpers.dart';

class CompetitionModel {
  const CompetitionModel({
    required this.id,
    required this.name,
    required this.category,
    required this.deadline,
    required this.status,
    required this.interestCount,
  });

  final String id;
  final String name;
  final String category;
  final String deadline;
  final String status;
  final int interestCount;

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: parseString(json['id'] ?? json['competition_id']),
      name: parseString(json['title'] ?? json['name']),
      category: parseString(json['category']),
      deadline: parseString(json['deadline'], fallback: 'Belum ditentukan'),
      status: parseString(
        json['verification_status'] ?? json['status'],
        fallback: 'Terverifikasi',
      ),
      interestCount: parseInt(
        json['interest_count'] ?? json['interestCount'],
        fallback: 0,
      ),
    );
  }

  CompetitionModel copyWith({
    String? id,
    String? name,
    String? category,
    String? deadline,
    String? status,
    int? interestCount,
  }) {
    return CompetitionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      interestCount: interestCount ?? this.interestCount,
    );
  }
}
