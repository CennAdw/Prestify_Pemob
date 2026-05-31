import 'model_helpers.dart';

class MentorshipRequestModel {
  const MentorshipRequestModel({
    required this.id,
    required this.teamId,
    required this.lecturerId,
    required this.teamName,
    required this.competitionName,
    required this.proposalTitle,
    required this.proposalSummary,
    required this.proposalLink,
    required this.status,
  });

  final String id;
  final String teamId;
  final String lecturerId;
  final String teamName;
  final String competitionName;
  final String proposalTitle;
  final String proposalSummary;
  final String proposalLink;
  final String status;

  factory MentorshipRequestModel.fromJson(Map<String, dynamic> json) {
    final team = json['teams'] is Map<String, dynamic>
        ? json['teams'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return MentorshipRequestModel(
      id: parseString(json['id']),
      teamId: parseString(json['team_id']),
      lecturerId: parseString(json['lecturer_id']),
      teamName: parseString(team['team_name'], fallback: 'Tim lomba'),
      competitionName: parseString(team['competition_name'], fallback: '-'),
      proposalTitle: parseString(json['proposal_title']),
      proposalSummary: parseString(json['proposal_summary']),
      proposalLink: parseString(json['proposal_link']),
      status: parseString(json['status'], fallback: 'pending'),
    );
  }
}
