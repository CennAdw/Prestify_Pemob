import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
// 1. IMPORT WIDGET CUSTOM KAMU DI SINI
import '../../core/widgets/refresh_indicator.dart'; 
import '../../data/app_state.dart';

class LecturerDashboardScreen extends StatefulWidget {
  const LecturerDashboardScreen({super.key});

  @override
  State<LecturerDashboardScreen> createState() =>
      _LecturerDashboardScreenState();
}

class _LecturerDashboardScreenState extends State<LecturerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadMentoringRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final waitingCount =
        state.mentoringRequests.where((r) => r.status == 'Menunggu').length;
    final acceptedCount =
        state.mentoringRequests.where((r) => r.status == 'Diterima').length;

    return Scaffold(
      backgroundColor: AppColors.backgroundSoftGray,
      // 2. BUNGKUS SINGLECHILDSCROLLVIEW DENGAN WIDGET CUSTOM
      body: CommonRefreshIndicator(
        onRefresh: () async {
          // Fungsi untuk mengambil data request bimbingan terbaru dari API
          await state.loadMentoringRequests();
        },
        child: SingleChildScrollView(
          // 3. TAMBAHKAN PHYSICS BIAR BISA DI-PULL DOWN WALAU DATA KOSONG
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.gradientStart, AppColors.gradientMid],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dashboard Dosen',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.white.withAlpha(200),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Edit profil
                            IconButton(
                              tooltip: 'Edit Profil',
                              onPressed: () =>
                                  _showEditProfileDialog(context, state),
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                            // Logout
                            IconButton(
                              tooltip: 'Keluar',
                              onPressed: () async {
                                await state.signOut();
                                if (!context.mounted) return;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (_) => false,
                                );
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Halo, Dosen Pembimbing 👋',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.lecturerUser.name,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white.withAlpha(200),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.hourglass_top_rounded,
                              label: '$waitingCount Menunggu',
                              color: AppColors.accentYellow,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              icon: Icons.check_circle_rounded,
                              label: '$acceptedCount Diterima',
                              color: AppColors.successGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status card ────────────────────────────────────────────
                    CustomCard(
                      elevation: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.supervisor_account_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status Bimbingan',
                                      style: AppTextStyles.subtitle,
                                    ),
                                    Text(
                                      '$waitingCount request menunggu keputusan',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kuota terisi',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: state.lecturerUser.maxQuota > 0
                                            ? state.lecturerUser.currentQuota /
                                                state.lecturerUser.maxQuota
                                            : 0,
                                        minHeight: 8,
                                        backgroundColor: AppColors.borderLight,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${state.lecturerUser.currentQuota}/${state.lecturerUser.maxQuota}',
                                style: AppTextStyles.title.copyWith(
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tim aktif dibimbing',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Request bimbingan masuk ────────────────────────────────
                    const SectionHeader(title: 'Request Bimbingan Masuk'),
                    const SizedBox(height: 12),

                    if (state.isMentoringRequestsLoading) ...[
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.primaryBlue,
                        backgroundColor: AppColors.borderLight,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (state.mentoringRequestError != null) ...[
                      _ErrorBanner(message: state.mentoringRequestError!),
                      const SizedBox(height: 12),
                    ],

                    if (state.mentoringRequests.isEmpty)
                      _EmptyRequests()
                    else
                      ...state.mentoringRequests.map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _MentoringRequestCard(request: request),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit profil dosen ──────────────────────────────────────────────────────
  Future<void> _showEditProfileDialog(
    BuildContext context,
    dynamic state,
  ) async {
    final lecturer = state.lecturerUser;
    final nameCtrl = TextEditingController(text: lecturer.name);
    final facultyCtrl = TextEditingController(text: lecturer.faculty);
    final quotaCtrl = TextEditingController(
      text: lecturer.maxQuota.toString(),
    );
    final expertiseCtrl = TextEditingController(
      text: (lecturer.expertise as List<String>).join(', '),
    );
    final expCtrl = TextEditingController(
      text: (lecturer.experiences as List<String>).join('\n'),
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Nama Lengkap'),
              _field(nameCtrl, 'Nama dosen'),
              _gap,
              _label('Fakultas'),
              _field(facultyCtrl, 'Nama fakultas'),
              _gap,
              _label('Kuota Bimbingan'),
              _field(
                quotaCtrl,
                'Maks. mahasiswa',
                keyboardType: TextInputType.number,
              ),
              _gap,
              _label('Keahlian (pisahkan dengan koma)'),
              _field(expertiseCtrl, 'Contoh: Flutter, AI, UI/UX'),
              _gap,
              _label('Pengalaman (satu per baris)'),
              TextField(
                controller: expCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecor('Satu pengalaman per baris...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final quota = int.tryParse(quotaCtrl.text.trim()) ??
                  lecturer.maxQuota;
              final expertise = expertiseCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final experiences = expCtrl.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              Navigator.pop(ctx);
              final msg = await state.updateLecturerProfile(
                name: nameCtrl.text.trim(),
                faculty: facultyCtrl.text.trim(),
                maxQuota: quota,
                expertise: expertise,
                experiences: experiences,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    facultyCtrl.dispose();
    quotaCtrl.dispose();
    expertiseCtrl.dispose();
    expCtrl.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.subtitle),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _inputDecor(hint),
      );

  static const Widget _gap = SizedBox(height: 14);

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.backgroundSoftGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      );
}

// ── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.white.withAlpha(230),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderFocus),
      ),
      child: Text(
        message,
        style: AppTextStyles.small.copyWith(color: AppColors.primaryBlue),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'Belum ada request bimbingan.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Card request bimbingan ────────────────────────────────────────────────────

class _MentoringRequestCard extends StatelessWidget {
  const _MentoringRequestCard({required this.request});
  final MentoringRequest request;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isWaiting = request.status == 'Menunggu';

    return CustomCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.teamName, style: AppTextStyles.subtitle),
                    const SizedBox(height: 3),
                    Text(request.competitionName, style: AppTextStyles.muted),
                  ],
                ),
              ),
              SkillChip(
                label: request.status,
                backgroundColor: _statusBg(request.status),
                textColor: _statusColor(request.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (request.proposalTitle.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.title_rounded,
                  size: 15,
                  color: AppColors.textGray,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.proposalTitle,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showProposalDetail(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textBody,
                    side: const BorderSide(color: AppColors.borderMedium),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text(
                    'Proposal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isWaiting
                      ? () async {
                          final msg = await state.updateMentoringRequest(
                            request.id,
                            'Diterima',
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(msg)));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Terima',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isWaiting
                      ? () async {
                          final msg = await state.updateMentoringRequest(
                            request.id,
                            'Ditolak',
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(msg)));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertCoral,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text(
                    'Tolak',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProposalDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Proposal — ${request.teamName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Judul Proposal', style: AppTextStyles.subtitle),
              const SizedBox(height: 6),
              Text(
                request.proposalTitle.isEmpty ? '-' : request.proposalTitle,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              const Text('Ringkasan', style: AppTextStyles.subtitle),
              const SizedBox(height: 6),
              Text(
                request.proposalSummary.isEmpty
                    ? 'Tidak ada ringkasan.'
                    : request.proposalSummary,
                style: AppTextStyles.body.copyWith(color: AppColors.textGray),
              ),
              const SizedBox(height: 16),
              const Text('File Proposal', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              if (request.proposalLink.isEmpty)
                Text(
                  'Tidak ada file yang dilampirkan.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(request.proposalLink);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.alertCoral,
                    size: 18,
                  ),
                  label: const Text('Buka File PDF'),
                ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Lihat Detail Tim',
                icon: Icons.groups_rounded,
                outlined: true,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/team-detail',
                    arguments: request.teamId,
                  );
                },
              ),
            ],
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

  Color _statusColor(String status) {
    if (status == 'Diterima') return AppColors.successGreen;
    if (status == 'Ditolak') return AppColors.alertCoral;
    return AppColors.warningAmber;
  }

  Color _statusBg(String status) {
    if (status == 'Diterima') return AppColors.successGreenLight;
    if (status == 'Ditolak') return AppColors.alertCoralLight;
    return AppColors.warningAmberLight;
  }
}