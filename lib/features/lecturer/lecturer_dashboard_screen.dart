import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
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
    final waitingCount = state.mentoringRequests
        .where((request) => request.status == 'Menunggu')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dosen'),
        actions: [
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
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              color: AppColors.primaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Dosen Pembimbing',
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.lecturerUser.name,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.lightBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.supervisor_account_rounded,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Mentoring',
                              style: AppTextStyles.subtitle,
                            ),
                            Text(
                              '$waitingCount request menunggu keputusan',
                              style: AppTextStyles.muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: AppColors.lightBlue,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kuota aktif 2/5 tim bimbingan',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Request Bimbingan Masuk'),
            const SizedBox(height: 10),
            if (state.isMentoringRequestsLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.mentoringRequestError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.mentoringRequestError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (state.mentoringRequests.isEmpty)
              CustomCard(
                child: Text(
                  'Belum ada request bimbingan dari Supabase.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
              )
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
    );
  }
}

class _MentoringRequestCard extends StatelessWidget {
  const _MentoringRequestCard({required this.request});

  final MentoringRequest request;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isWaiting = request.status == 'Menunggu';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.teamName, style: AppTextStyles.subtitle),
                    const SizedBox(height: 4),
                    Text(request.competitionName, style: AppTextStyles.muted),
                  ],
                ),
              ),
              SkillChip(
                label: request.status,
                backgroundColor: _statusBackground(request.status),
                textColor: _statusColor(request.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PrimaryButton(
                label: 'Lihat Proposal',
                outlined: true,
                isExpanded: false,
                icon: Icons.description_outlined,
                onPressed: () => _showProposal(context),
              ),
              PrimaryButton(
                label: 'Terima',
                isExpanded: false,
                icon: Icons.check_rounded,
                backgroundColor: AppColors.successGreen,
                onPressed: isWaiting
                    ? () async {
                        final message = await state.updateMentoringRequest(
                          request.id,
                          'Diterima',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    : null,
              ),
              PrimaryButton(
                label: 'Tolak',
                isExpanded: false,
                icon: Icons.close_rounded,
                backgroundColor: AppColors.alertCoral,
                onPressed: isWaiting
                    ? () async {
                        final message = await state.updateMentoringRequest(
                          request.id,
                          'Ditolak',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProposal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Proposal ${request.teamName}'),
        content: Text(
          request.proposalSummary.isEmpty
              ? 'Ringkasan proposal ${request.competitionName}: validasi masalah, rancangan solusi, timeline sprint, dan kebutuhan mentoring mingguan.'
              : request.proposalSummary,
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
    return AppColors.deepNavy;
  }

  Color _statusBackground(String status) {
    if (status == 'Diterima') return AppColors.successGreen.withAlpha(28);
    if (status == 'Ditolak') return AppColors.alertCoral.withAlpha(26);
    return AppColors.accentYellow.withAlpha(48);
  }
}
