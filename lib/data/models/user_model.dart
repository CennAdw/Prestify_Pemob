enum UserRole { student, lecturer }

UserRole userRoleFromString(String value) {
  switch (value.toLowerCase()) {
    case 'lecturer':
    case 'dosen':
      return UserRole.lecturer;
    case 'student':
    case 'mahasiswa':
    default:
      return UserRole.student;
  }
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Mahasiswa';
      case UserRole.lecturer:
        return 'Dosen';
    }
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.faculty,
    this.program,
    this.year,
    this.skills = const [],
    this.avatarUrl,
    this.portfolioUrl,
    this.emailVerified = false,
    this.registrationCompleted = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? nim;
  final String? faculty;
  final String? program;
  final int? year;
  final List<String> skills;
  final String? avatarUrl;
  final String? portfolioUrl;
  final bool emailVerified;
  final bool registrationCompleted;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:
          (json['student_id'] ??
                  json['lecturer_id'] ??
                  json['profile_id'] ??
                  json['id'] ??
                  json['user_id'] ??
                  '')
              .toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: userRoleFromString((json['role'] ?? 'student').toString()),
      nim: json['nim']?.toString(),
      faculty: json['faculty']?.toString(),
      program: json['study_program']?.toString() ?? json['program']?.toString(),
      year: json['batch_year'] is int
          ? json['batch_year'] as int
          : int.tryParse(json['batch_year']?.toString() ?? '') ??
                int.tryParse(json['year']?.toString() ?? ''),
      skills: json['skills'] is List
          ? (json['skills'] as List).map((item) => item.toString()).toList()
          : (json['skills']
                    ?.toString()
                    .split(',')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList() ??
                const []),
      avatarUrl: json['avatar_url']?.toString(),
      portfolioUrl: json['portfolio_url']?.toString(),
      emailVerified: json['email_verified_at'] != null,
      registrationCompleted: json['registration_completed'] == true,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? nim,
    String? faculty,
    String? program,
    int? year,
    List<String>? skills,
    String? avatarUrl,
    String? portfolioUrl,
    bool? emailVerified,
    bool? registrationCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      nim: nim ?? this.nim,
      faculty: faculty ?? this.faculty,
      program: program ?? this.program,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      registrationCompleted:
          registrationCompleted ?? this.registrationCompleted,
    );
  }
}
