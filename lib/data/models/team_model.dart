import 'model_helpers.dart';

class TeamMember {
  const TeamMember({
    required this.studentId,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String studentId;
  final String name;
  final String role;
  final String? avatarUrl;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    // Handle nested users(avatar_url) structure from Supabase join
    final usersData = json['users'];
    final avatarUrl = usersData is Map 
        ? usersData['avatar_url']?.toString() 
        : json['avatar_url']?.toString();
    
    return TeamMember(
      studentId: parseString(json['student_id'] ?? json['studentId'] ?? ''),
      name: parseString(json['name'] ?? json['student_name']),
      role: parseString(json['role'] ?? json['role_in_team']),
      avatarUrl: avatarUrl,
    );
  }
}

class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.competitionName,
    required this.description,
    required this.requiredSkills,
    required this.currentMembers,
    required this.maxMembers,
    required this.deadline,
    required this.matchingScore,
    required this.status,
    required this.members,
    this.posterUrl = '',
    this.notes = '',
    this.leaderId = '',
    this.hasRequested = false,
  });

  final String id;
  final String name;
  final String competitionName;
  final String description;
  final List<String> requiredSkills;
  final int currentMembers;
  final int maxMembers;
  final String deadline;
  final int matchingScore;
  final String status;
  final List<TeamMember> members;
  final String posterUrl;
  final String notes;
  final String leaderId;
  final bool hasRequested;

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] ?? json['team_members'];
    return TeamModel(
      id: parseString(json['id'] ?? json['team_id']),
      name: parseString(json['team_name'] ?? json['name']),
      competitionName: parseString(
        json['competition_title'] ??
            json['competition_name'] ??
            json['competitionName'],
      ),
      description: parseString(json['description']),
      requiredSkills: parseStringList(
        json['required_skills'] ?? json['requiredSkills'],
      ),
      currentMembers: parseInt(
        json['current_members'] ?? json['currentMembers'],
        fallback: membersJson is List ? membersJson.length : 0,
      ),
      maxMembers: parseInt(
        json['max_members'] ?? json['maxMembers'],
        fallback: 5,
      ),
      deadline: parseString(json['deadline'], fallback: 'Belum ditentukan'),
      matchingScore: parseInt(
        json['matching_score'] ?? json['matchingScore'],
        fallback: 0,
      ),
      status: parseString(
        json['recruitment_status'] ?? json['status'],
        fallback: 'Open Recruitment',
      ),
      posterUrl: parseString(
        json['poster_url'] ?? json['posterUrl'] ?? json['posterImageUrl'],
      ),
      notes: parseString(json['notes'] ?? json['competition_notes']),
      leaderId: parseString(json['leader_id'] ?? json['leaderId']),
      members: membersJson is List
          ? membersJson
                .whereType<Map<String, dynamic>>()
                .map(TeamMember.fromJson)
                .toList()
          : const [],
      hasRequested:
          json['has_requested'] == true || json['hasRequested'] == true,
    );
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? competitionName,
    String? description,
    List<String>? requiredSkills,
    int? currentMembers,
    int? maxMembers,
    String? deadline,
    int? matchingScore,
    String? status,
    List<TeamMember>? members,
    String? posterUrl,
    String? notes,
    String? leaderId,
    bool? hasRequested,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      competitionName: competitionName ?? this.competitionName,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      currentMembers: currentMembers ?? this.currentMembers,
      maxMembers: maxMembers ?? this.maxMembers,
      deadline: deadline ?? this.deadline,
      matchingScore: matchingScore ?? this.matchingScore,
      status: status ?? this.status,
      members: members ?? this.members,
      posterUrl: posterUrl ?? this.posterUrl,
      notes: notes ?? this.notes,
      leaderId: leaderId ?? this.leaderId,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}