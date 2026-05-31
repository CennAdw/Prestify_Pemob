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

extension UserRoleApiValue on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.lecturer:
        return 'lecturer';
    }
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.program,
    this.year,
    this.skills = const [],
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? program;
  final int? year;
  final List<String> skills;
  final String? avatarUrl;

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.apiValue,
      'program': program,
      'year': year,
      'skills': skills,
      'avatar_url': avatarUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? program,
    int? year,
    List<String>? skills,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      program: program ?? this.program,
      year: year ?? this.year,
      skills: skills ?? this.skills,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
