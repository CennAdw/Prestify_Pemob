import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/join_request_model.dart';
import '../../data/models/user_model.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final String teamId;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final List<JoinRequestModel> _joinRequests = [];
  bool _isRequestsLoading = false;
  String? _requestError;
  bool _isMemberDetailsLoading = false;
  UserModel? _selectedMemberDetails;
  List<AchievementModel> _selectedMemberAchievements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppStateScope.of(context)
            .loadTeamDetail(widget.teamId)
            .then((_) {
          if (!mounted) return;
          _loadJoinRequestsIfLeader();
        });
      }
    });
  }

  Future<void> _loadJoinRequestsIfLeader() async {
    final state = AppStateScope.of(context);
    final team = state.teamById(widget.teamId);
    if (team.leaderId != state.student.id) return;

    setState(() {
      _isRequestsLoading = true;
      _requestError = null;
    });

    try {
      final requests = await state.teamRepository.getTeamJoinRequests(
        widget.teamId,
      );
      if (!mounted) return;
      setState(() {
        _joinRequests
          ..clear()
          ..addAll(requests);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = 'Gagal memuat permintaan: $error';
      });
    }

    if (!mounted) return;
    setState(() {
      _isRequestsLoading = false;
    });
  }

  Future<void> _handleJoinRequestAction(
    String requestId,
    String status,
  ) async {
    final state = AppStateScope.of(context);
    final message = await state.respondToJoinRequest(
      requestId: requestId,
      status: status,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await state.loadTeamDetail(widget.teamId);
    await _loadJoinRequestsIfLeader();
  }

  Future<void> _loadMemberDetails(String studentId) async {
    debugPrint('MEMBER ID = $studentId');
    setState(() {
      _isMemberDetailsLoading = true;
      _selectedMemberDetails = null;
      _selectedMemberAchievements = [];
    });

    try {
      final state = AppStateScope.of(context);
      final userDetails = await state.studentRepository.getUserDetails(studentId);
      final achievements = await state.studentRepository.getAchievements(studentId);
      
      if (!mounted) return;
      setState(() {
        _selectedMemberDetails = userDetails;
        _selectedMemberAchievements = achievements;
        _isMemberDetailsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isMemberDetailsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail anggota: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final team = state.teamById(widget.teamId);
    final isAlreadyMember = state.student.id.isNotEmpty &&
      (team.leaderId == state.student.id ||
        team.members.any(
          (member) => member.studentId.isNotEmpty &&
            member.studentId == state.student.id,
        ));
    final studentSkills = state.student.skills
        .map((skill) => skill.toLowerCase())
        .toSet();
    final matchedSkills = team.requiredSkills
        .where((skill) => studentSkills.contains(skill.toLowerCase()))
        .toList();
    final missingSkills = team.requiredSkills
        .where((skill) => !studentSkills.contains(skill.toLowerCase()))
        .toList();
    
    // Calculate matching score dynamically
    final dynamicMatchingScore = team.requiredSkills.isEmpty 
        ? 0 
        : ((matchedSkills.length / team.requiredSkills.length) * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              color: AppColors.primaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillChip(
                    label: team.status,
                    backgroundColor: AppColors.white.withAlpha(34),
                    textColor: AppColors.white,
                    compact: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    team.name,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.competitionName,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.lightBlue,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isTeamsLoading) ...[
                    const LinearProgressIndicator(
                      minHeight: 4,
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.lightBlue,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.teamError != null) ...[
                    CustomCard(
                      color: AppColors.lightBlue,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        state.teamError!,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deskripsi Tim',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          team.description,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Poster Lomba',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 12),
                        if (team.posterUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              team.posterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 180,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSoftGray,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text('Gagal memuat poster.'),
                                ),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundSoftGray,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSoftGray,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.photo_size_select_actual_rounded,
                                  size: 40,
                                  color: AppColors.primaryBlue,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Belum ada poster lomba.',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catatan Lomba',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          team.notes.isEmpty
                              ? 'Belum ada catatan tambahan dari tim.'
                              : team.notes,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Matching Score',
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                            Text(
                              '$dynamicMatchingScore%',
                              style: AppTextStyles.title.copyWith(
                                color: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: dynamicMatchingScore / 100,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(99),
                          backgroundColor: AppColors.lightBlue,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Alasan Kecocokan',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 10),
                        if (team.requiredSkills.isEmpty)
                          Text(
                            'Tim belum mengisi kebutuhan skill.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textGray,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...matchedSkills.map(
                                (skill) => SkillChip(
                                  label: skill,
                                  icon: Icons.check_circle_rounded,
                                  backgroundColor: const Color(0xFFEAF8EE),
                                  textColor: AppColors.successGreen,
                                ),
                              ),
                              ...missingSkills.map(
                                (skill) => SkillChip(
                                  label: skill,
                                  icon: Icons.info_rounded,
                                  backgroundColor: const Color(0xFFFFF5F3),
                                  textColor: AppColors.alertCoral,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Anggota Tim'),
                  const SizedBox(height: 10),
                  ...team.members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.lightBlue,
                              child: Text(
                                member.name.isEmpty
                                    ? '?'
                                    : member.name.characters.first,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(member.role, style: AppTextStyles.muted),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                debugPrint('CLICK MEMBER ID = ${member.studentId}');
                                await _loadMemberDetails(member.studentId);
                                if (!mounted) return;
                                if (!context.mounted) return;
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Detail Anggota'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: _isMemberDetailsLoading
                                          ? const Center(
                                              child: CircularProgressIndicator(),
                                            )
                                          : _selectedMemberDetails == null
                                              ? const Text(
                                                  'Gagal memuat detail anggota.',
                                                )
                                              : SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _selectedMemberDetails!
                                                                .name
                                                                .isEmpty
                                                            ? member.name
                                                            : _selectedMemberDetails!
                                                                .name,
                                                        style: AppTextStyles
                                                            .subtitle,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Peran: ${member.role}',
                                                        style: AppTextStyles.body,
                                                      ),
                                                      const SizedBox(height: 12),
                                                      const Text(
                                                        'Skill',
                                                        style: AppTextStyles
                                                            .subtitle,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      if (_selectedMemberDetails!
                                                              .skills
                                                              .isEmpty)
                                                        Text(
                                                          'Belum ada skill.',
                                                          style: AppTextStyles.body
                                                              .copyWith(
                                                            color: AppColors
                                                                .textGray,
                                                          ),
                                                        )
                                                      else
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 8,
                                                          children: _selectedMemberDetails!
                                                              .skills
                                                              .map((skill) =>
                                                                  SkillChip(
                                                                    label: skill,
                                                                  ))
                                                              .toList(),
                                                        ),
                                                      const SizedBox(height: 12),
                                                      const Text(
                                                        'Prestasi',
                                                        style: AppTextStyles
                                                            .subtitle,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      if (_selectedMemberAchievements
                                                          .isEmpty)
                                                        Text(
                                                          'Belum ada prestasi.',
                                                          style: AppTextStyles.body
                                                              .copyWith(
                                                            color: AppColors
                                                                .textGray,
                                                          ),
                                                        )
                                                      else
                                                        ..._selectedMemberAchievements
                                                            .map((achievement) =>
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          8),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        achievement.title,
                                                                        style: AppTextStyles
                                                                            .body,
                                                                      ),
                                                                      Text(
                                                                        achievement.subtitle,
                                                                        style: AppTextStyles
                                                                            .small
                                                                            .copyWith(
                                                                          color: AppColors
                                                                              .textGray,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )),
                                                      const SizedBox(height: 12),
                                                      const Text(
                                                        'Portfolio',
                                                        style: AppTextStyles
                                                            .subtitle,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      if (_selectedMemberDetails!
                                                              .portfolioUrl ==
                                                          null ||
                                                          _selectedMemberDetails!
                                                              .portfolioUrl!
                                                              .isEmpty)
                                                        Text(
                                                          'Belum ada portfolio.',
                                                          style: AppTextStyles.body
                                                              .copyWith(
                                                            color: AppColors
                                                                .textGray,
                                                          ),
                                                        )
                                                      else
                                                        OutlinedButton.icon(
                                                          onPressed: () {
                                                            // Download portfolio
                                                            final portfolioUrl = _selectedMemberDetails!.portfolioUrl!;
                                                            // TODO: Implement download functionality
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Download portfolio: $portfolioUrl')),
                                                            );
                                                          },
                                                          icon: const Icon(Icons.download),
                                                          label: const Text('Download Portfolio'),
                                                        ),
                                                      const SizedBox(height: 12),
                                                      const Text(
                                                        'Informasi Akademik',
                                                        style: AppTextStyles
                                                            .subtitle,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Fakultas: ${_selectedMemberDetails?.faculty ?? "-"}',
                                                        style: AppTextStyles.body,
                                                      ),
                                                      Text(
                                                        'Program Studi: ${_selectedMemberDetails?.program ?? "-"}',
                                                        style: AppTextStyles.body,
                                                      ),
                                                      Text(
                                                        'Angkatan: ${_selectedMemberDetails?.year ?? "-"}',
                                                        style: AppTextStyles.body,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Tutup'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Lihat'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (team.leaderId == state.student.id) ...[
                    const SizedBox(height: 18),
                    const SectionHeader(title: 'Permintaan Bergabung'),
                    const SizedBox(height: 10),
                    if (_isRequestsLoading) ...[
                      const Center(child: CircularProgressIndicator()),
                    ] else if (_requestError != null) ...[
                      CustomCard(
                        color: AppColors.lightBlue,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _requestError!,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ] else if (_joinRequests.isEmpty)
                      CustomCard(
                        child: Text(
                          'Belum ada permintaan bergabung dari anggota.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      )
                    else
                      ..._joinRequests.map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CustomCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.lightBlue,
                                      child: Text(
                                        request.studentName.isEmpty
                                            ? '?'
                                            : request.studentName.characters.first,
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.studentName.isEmpty
                                                ? 'Mahasiswa'
                                                : request.studentName,
                                            style: AppTextStyles.subtitle.copyWith(
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            'Peran: ${request.appliedRole}',
                                            style: AppTextStyles.muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      request.status,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  request.message.isEmpty
                                      ? 'Tidak ada pesan tambahan.'
                                      : request.message,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (request.status == 'Menunggu')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: PrimaryButton(
                                          label: 'Terima',
                                          icon: Icons.check_rounded,
                                          onPressed: () =>
                                              _handleJoinRequestAction(
                                            request.id,
                                            'Diterima',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _handleJoinRequestAction(
                                            request.id,
                                            'Ditolak',
                                          ),
                                          child: const Text('Tolak'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  const SectionHeader(title: 'Skill yang Dibutuhkan'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: team.requiredSkills
                        .map((skill) => SkillChip(label: skill))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: isAlreadyMember
                        ? 'Sudah menjadi anggota'
                        : team.hasRequested
                            ? 'Menunggu Persetujuan'
                            : 'Ajukan Bergabung',
                    icon: isAlreadyMember
                        ? Icons.check_circle_rounded
                        : team.hasRequested
                            ? Icons.hourglass_top_rounded
                            : Icons.send_rounded,
                    onPressed: team.hasRequested || isAlreadyMember
                        ? null
                        : () async {
                            final message = await state.requestJoinTeamApi(
                              team.id,
                            );
                            if (!context.mounted) return;
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Berhasil'),
                                content: Text(message),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Oke'),
                                  ),
                                ],
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
