import 'model_helpers.dart';
import 'user_model.dart';

class StudentModel {
  const StudentModel({
    required this.id,
    required this.user,
    required this.nim,
    required this.faculty,
    required this.studyProgram,
    required this.batchYear,
    required this.skills,
    required this.interests,
    required this.portfolioLink,
    required this.bio,
  });

  final String id;
  final UserModel user;
  final String nim;
  final String faculty;
  final String studyProgram;
  final int batchYear;
  final List<String> skills;
  final List<String> interests;
  final String portfolioLink;
  final String bio;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: parseString(json['id'] ?? json['student_id']),
      user: UserModel.fromJson(json),
      nim: parseString(json['nim'], fallback: '-'),
      faculty: parseString(json['faculty']),
      studyProgram: parseString(json['study_program']),
      batchYear: parseInt(json['batch_year'], fallback: 2024),
      skills: parseStringList(json['skills']),
      interests: parseStringList(json['interests']),
      portfolioLink: parseString(json['portfolio_link']),
      bio: parseString(json['bio']),
    );
  }
}
