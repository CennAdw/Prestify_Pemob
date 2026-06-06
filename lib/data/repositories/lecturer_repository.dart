import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../models/lecturer_model.dart';
import '../models/mentorship_request_model.dart';
import 'repository_helpers.dart';

class LecturerRepository {
  const LecturerRepository();

  Future<List<LecturerModel>> getLecturers() async {
    final data = await SupabaseService.client
        .from('lecturers')
        .select()
        .order('id');
    return asMapList(data).map(LecturerModel.fromJson).toList();
  }

  Future<LecturerModel> getLecturerDetail(String id) async {
    final data = await SupabaseService.client
        .from('lecturers')
        .select()
        .eq('id', id)
        .limit(1);
    final lecturers = asMapList(data);
    if (lecturers.isEmpty) throw StateError('Dosen tidak ditemukan.');
    return LecturerModel.fromJson(lecturers.first);
  }

  /// Upload file proposal PDF ke Supabase Storage.
  /// Mengembalikan public URL-nya, atau null jika gagal.
  Future<String?> uploadProposalPdf(File file, String lecturerId) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id ?? 'unknown';
      final ext = file.path.split('.').last;
      final path = 'proposals/$lecturerId/${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      print('Uploading PDF to path: $path');
      print('Bucket: mentorship-proposals');

      await SupabaseService.client.storage
          .from('mentorship-proposals')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = SupabaseService.client.storage
          .from('mentorship-proposals')
          .getPublicUrl(path);

      print('Upload successful. Public URL: $publicUrl');
      return publicUrl;
    } catch (error) {
      print('PDF Upload Error: $error');
      return null;
    }
  }

  Future<void> requestMentorship({
    required String teamId,
    required String lecturerId,
    required String proposalTitle,
    required String proposalSummary,
    required String proposalLink,
  }) async {
    await SupabaseService.client.from('mentorship_requests').insert({
      'team_id': teamId,
      'lecturer_id': lecturerId,
      'proposal_title': proposalTitle,
      'proposal_summary': proposalSummary,
      'proposal_link': proposalLink,
      'status': 'Menunggu',
    });
  }

  Future<List<MentorshipRequestModel>> getMentorshipRequests(
    String lecturerId,
  ) async {
    final data = await SupabaseService.client
        .from('mentorship_requests')
        .select('*, teams(team_name, competition_name)')
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
    return asMapList(data).map(MentorshipRequestModel.fromJson).toList();
  }

  Future<void> updateMentorshipRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await SupabaseService.client
        .from('mentorship_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  /// Update data profil dosen di tabel `lecturers`.
  Future<void> updateLecturerProfile({
    required String lecturerId,
    required String name,
    required String faculty,
    required int maxQuota,
    required List<String> expertise,
    required List<String> experiences,
  }) async {
    await SupabaseService.client.from('lecturers').update({
      'name': name,
      'faculty': faculty,
      'mentoring_quota': maxQuota,
      'expertise': expertise,
      'experiences': experiences,
    }).eq('id', lecturerId);
  }
}