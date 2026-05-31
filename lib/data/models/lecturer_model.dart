import 'model_helpers.dart';

class LecturerModel {
  const LecturerModel({
    required this.id,
    required this.name,
    required this.faculty,
    required this.expertise,
    required this.status,
    required this.currentQuota,
    required this.maxQuota,
    required this.experiences,
    this.hasRequested = false,
  });

  final String id;
  final String name;
  final String faculty;
  final List<String> expertise;
  final String status;
  final int currentQuota;
  final int maxQuota;
  final List<String> experiences;
  final bool hasRequested;

  bool get isAvailable => status == 'Tersedia' && currentQuota < maxQuota;

  factory LecturerModel.fromJson(Map<String, dynamic> json) {
    return LecturerModel(
      id: parseString(json['id'] ?? json['lecturer_id']),
      name: parseString(json['name']),
      faculty: parseString(json['faculty']),
      expertise: parseStringList(json['expertise']),
      status: parseString(
        json['mentoring_status'] ?? json['status'],
        fallback: 'Tersedia',
      ),
      currentQuota: parseInt(
        json['current_mentoring_count'] ?? json['currentQuota'],
        fallback: 0,
      ),
      maxQuota: parseInt(
        json['mentoring_quota'] ?? json['maxQuota'],
        fallback: 5,
      ),
      experiences: parseStringList(json['experiences']),
      hasRequested:
          json['has_requested'] == true || json['hasRequested'] == true,
    );
  }

  LecturerModel copyWith({
    String? id,
    String? name,
    String? faculty,
    List<String>? expertise,
    String? status,
    int? currentQuota,
    int? maxQuota,
    List<String>? experiences,
    bool? hasRequested,
  }) {
    return LecturerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      faculty: faculty ?? this.faculty,
      expertise: expertise ?? this.expertise,
      status: status ?? this.status,
      currentQuota: currentQuota ?? this.currentQuota,
      maxQuota: maxQuota ?? this.maxQuota,
      experiences: experiences ?? this.experiences,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}
