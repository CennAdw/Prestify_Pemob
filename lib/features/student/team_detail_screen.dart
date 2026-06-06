import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppStateScope.of(context).loadTeamDetail(widget.teamId).then((_) {
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
          ..addAll(requests.where((r) => r.status == 'Menunggu'));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _requestError = 'Gagal memuat permintaan: $error';
      });
    }

    if (!mounted) return;
    setState(() => _isRequestsLoading = false);
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    await state.loadTeamDetail(widget.teamId);
    await _loadJoinRequestsIfLeader();
  }

  Future<void> _launchPortfolioUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL portfolio tidak valid.')),
      );
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka URL portfolio.')),
      );
    }
  }

  Future<void> _showJoinDialog(
    BuildContext context,
    dynamic state,
    String teamId,
  ) async {
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Bergabung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesan untuk ketua tim (opsional)',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Ceritakan motivasimu bergabung ke tim ini...',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.backgroundSoftGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    final msg = messageController.text.trim();
    messageController.dispose();
    if (confirmed != true || !mounted) return;
    final result = await state.requestJoinTeamApi(teamId, message: msg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  // ── Muat detail anggota lalu tampilkan dialog ─────────────────────────────
  //
  // FIX: Dulu dialog dibuka sebelum data selesai dimuat sehingga builder
  // membaca state yang masih null.  Sekarang kita tunggu data ready terlebih
  // dahulu, baru buka dialog dengan data yang sudah pasti ada.
  Future<void> _showMemberDetail(String studentId, String fallbackName) async {
    UserModel? userDetails;
    List<AchievementModel> achievements = [];

    // Tampilkan loading snackbar sementara fetch
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Memuat detail anggota...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final state = AppStateScope.of(context);
      userDetails = await state.studentRepository.getUserDetails(studentId);
      achievements = await state.studentRepository.getAchievements(studentId);
    } catch (_) {
      // error akan ditangani di bawah
    }

    if (!mounted) return;
    messenger.hideCurrentSnackBar();

    if (userDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail anggota.')),
      );
      return;
    }

    final displayName =
        userDetails.name.isEmpty ? fallbackName : userDetails.name;

    // ignore: use_build_context_synchronously
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Detail Anggota'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──────────────────────────────────────────────────
                Center(
                  child: _ProfileAvatar(
                    avatarUrl: userDetails!.avatarUrl,
                    name: displayName,
                    radius: 36,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Nama ────────────────────────────────────────────────────
                Center(
                  child: Text(displayName, style: AppTextStyles.subtitle),
                ),
                const SizedBox(height: 16),

                // ── Skill ───────────────────────────────────────────────────
                const Text('Skill', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                userDetails.skills.isEmpty
                    ? Text(
                        'Belum ada skill.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textGray),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: userDetails.skills
                            .map((s) => SkillChip(label: s))
                            .toList(),
                      ),
                const SizedBox(height: 12),

                // ── Prestasi ────────────────────────────────────────────────
                const Text('Prestasi', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                if (achievements.isEmpty)
                  Text(
                    'Belum ada prestasi.',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textGray),
                  )
                else
                  ...achievements.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: AppTextStyles.body),
                          Text(
                            a.subtitle,
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // ── Portfolio ───────────────────────────────────────────────
                const Text('Portfolio', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                userDetails.portfolioUrl == null ||
                        userDetails.portfolioUrl!.isEmpty
                    ? Text(
                        'Belum ada portfolio.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textGray),
                      )
                    : OutlinedButton.icon(
                        onPressed: () =>
                            _launchPortfolioUrl(userDetails!.portfolioUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka Portfolio'),
                      ),
                const SizedBox(height: 12),

                // ── Akademik ────────────────────────────────────────────────
                const Text('Informasi Akademik', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Text('Fakultas: ${userDetails.faculty ?? "-"}',
                    style: AppTextStyles.body),
                Text('Program Studi: ${userDetails.program ?? "-"}',
                    style: AppTextStyles.body),
                Text('Angkatan: ${userDetails.year ?? "-"}',
                    style: AppTextStyles.body),
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
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final team = state.teamById(widget.teamId);
    final isAlreadyMember = state.student.id.isNotEmpty &&
        (team.leaderId == state.student.id ||
            team.members.any(
              (m) => m.studentId.isNotEmpty && m.studentId == state.student.id,
            ));
    final isFull =
        team.maxMembers > 0 && team.members.length >= team.maxMembers;
    final studentSkills =
        state.student.skills.map((s) => s.toLowerCase()).toSet();
    final matchedSkills = team.requiredSkills
        .where((s) => studentSkills.contains(s.toLowerCase()))
        .toList();
    final missingSkills = team.requiredSkills
        .where((s) => !studentSkills.contains(s.toLowerCase()))
        .toList();
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
            // ── Hero header ────────────────────────────────────────────────
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
                    style:
                        AppTextStyles.headline.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.competitionName,
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.lightBlue),
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
                        style: AppTextStyles.small
                            .copyWith(color: AppColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Deskripsi ──────────────────────────────────────────────
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deskripsi Tim', style: AppTextStyles.subtitle),
                        const SizedBox(height: 8),
                        Text(
                          team.description,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Poster ─────────────────────────────────────────────────
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Poster Lomba', style: AppTextStyles.subtitle),
                        const SizedBox(height: 12),
                        if (team.posterUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              team.posterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 180,
                              errorBuilder: (_, _, _) => _posterPlaceholder(
                                  'Gagal memuat poster.'),
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : _posterPlaceholder(null, loading: true),
                            ),
                          )
                        else
                          _posterPlaceholder(null),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Catatan ────────────────────────────────────────────────
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Catatan Lomba', style: AppTextStyles.subtitle),
                        const SizedBox(height: 8),
                        Text(
                          team.notes.isEmpty
                              ? 'Belum ada catatan tambahan dari tim.'
                              : team.notes,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Matching score ─────────────────────────────────────────
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Matching Score',
                                  style: AppTextStyles.subtitle),
                            ),
                            Text(
                              '$dynamicMatchingScore%',
                              style: AppTextStyles.title
                                  .copyWith(color: AppColors.successGreen),
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
                        const Text('Alasan Kecocokan',
                            style: AppTextStyles.subtitle),
                        const SizedBox(height: 10),
                        if (team.requiredSkills.isEmpty)
                          Text(
                            'Tim belum mengisi kebutuhan skill.',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textGray),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...matchedSkills.map(
                                (s) => SkillChip(
                                  label: s,
                                  icon: Icons.check_circle_rounded,
                                  backgroundColor: const Color(0xFFEAF8EE),
                                  textColor: AppColors.successGreen,
                                ),
                              ),
                              ...missingSkills.map(
                                (s) => SkillChip(
                                  label: s,
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

                  // ── Anggota tim ────────────────────────────────────────────
                  const SectionHeader(title: 'Anggota Tim'),
                  const SizedBox(height: 10),
                  ...team.members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Avatar langsung tampil dari member.avatarUrl
                            _ProfileAvatar(
                              avatarUrl: member.avatarUrl,
                              name: member.name,
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: AppTextStyles.subtitle
                                        .copyWith(fontSize: 15),
                                  ),
                                  Text(member.role, style: AppTextStyles.muted),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              // FIX: Tidak ada state lokal yang di-share antar
                              // anggota.  Data di-fetch di dalam fungsi, lalu
                              // dialog baru dibuka setelah data ready →
                              // builder langsung dapat data final.
                              onPressed: () => _showMemberDetail(
                                member.studentId,
                                member.name,
                              ),
                              child: const Text('Lihat'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Permintaan bergabung (leader only) ────────────────────
                  if (team.leaderId == state.student.id) ...[
                    const SizedBox(height: 18),
                    const SectionHeader(title: 'Permintaan Bergabung'),
                    const SizedBox(height: 10),
                    if (_isRequestsLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_requestError != null)
                      CustomCard(
                        color: AppColors.lightBlue,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _requestError!,
                          style: AppTextStyles.small
                              .copyWith(color: AppColors.primaryBlue),
                        ),
                      )
                    else if (_joinRequests.isEmpty)
                      CustomCard(
                        child: Text(
                          'Belum ada permintaan bergabung dari anggota.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textGray),
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
                                    _ProfileAvatar(
                                      avatarUrl: null,
                                      name: request.studentName,
                                      radius: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.studentName,
                                            style: AppTextStyles.subtitle
                                                .copyWith(fontSize: 15),
                                          ),
                                          Text(
                                            request.message.isEmpty
                                                ? 'Tanpa pesan'
                                                : request.message,
                                            style: AppTextStyles.muted,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _showMemberDetail(
                                        request.studentId,
                                        request.studentName,
                                      ),
                                      child: const Text('Lihat'),
                                    ),
                                    if (request.status == 'Menunggu') ...[
                                      const SizedBox(width: 8),
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
                                      const SizedBox(width: 8),
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),

                  // ── Skill dibutuhkan ───────────────────────────────────────
                  const SectionHeader(title: 'Skill yang Dibutuhkan'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        team.requiredSkills.map((s) => SkillChip(label: s)).toList(),
                  ),
                  const SizedBox(height: 22),

                  // ── Tombol bergabung ───────────────────────────────────────
                  if (isFull && !isAlreadyMember)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSoftGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_off_rounded,
                              color: AppColors.textGray, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Tim sudah penuh (${team.members.length}/${team.maxMembers})',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
                          : () => _showJoinDialog(context, state, team.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder(String? label, {bool loading = false}) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.backgroundSoftGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_size_select_actual_rounded,
                    size: 40, color: AppColors.primaryBlue),
                const SizedBox(height: 10),
                Text(
                  label ?? 'Belum ada poster lomba.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
    );
  }
}

// ── Shared avatar widget ──────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.name,
    this.radius = 20,
  });

  final String? avatarUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.lightBlue,
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Text(
              initials,
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.8,
              ),
            ),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(
                    width: radius * 2,
                    height: radius * 2,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lightBlue,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}