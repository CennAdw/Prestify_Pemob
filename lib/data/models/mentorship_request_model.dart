import 'model_helpers.dart';

class MentorshipRequestModel {
  const MentorshipRequestModel({
    required this.id,
    required this.teamId,
    required this.lecturerId,
    required this.proposalTitle,
    required this.proposalSummary,
    required this.proposalLink,
    required this.status,
  });

  final String id;
  final String teamId;
  final String lecturerId;
  final String proposalTitle;
  final String proposalSummary;
  final String proposalLink;
  final String status;

  factory MentorshipRequestModel.fromJson(Map<String, dynamic> json) {
    return MentorshipRequestModel(
      id: parseString(json['id']),
      teamId: parseString(json['team_id']),
      lecturerId: parseString(json['lecturer_id']),
      proposalTitle: parseString(json['proposal_title']),
      proposalSummary: parseString(json['proposal_summary']),
      proposalLink: parseString(json['proposal_link']),
      status: parseString(json['status'], fallback: 'pending'),
    );
  }
}
