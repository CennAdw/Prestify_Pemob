import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/app_state.dart';
import 'team_detail_screen.dart';

class ApplicationHistoryScreen extends StatefulWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  State<ApplicationHistoryScreen> createState() =>
      _ApplicationHistoryScreenState();
}

class _ApplicationHistoryScreenState extends State<ApplicationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadApplicationHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final pendingRequests =
        state.applicationHistory.where((i) => i.status == 'Menunggu').toList();
    final approvedRequests =
        state.applicationHistory.where((i) => i.status == 'Diterima').toList();
    final rejectedRequests =
        state.applicationHistory.where((i) => i.status == 'Ditolak').toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: state.loadApplicationHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Ajuan', style: AppTextStyles.headline),
                      Text(
                        'Pantau status pengajuan bergabung ke tim.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textGray),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: state.loadApplicationHistory,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary chips
            if (state.applicationHistory.isNotEmpty) ...[
              Row(
                children: [
                  _SummaryChip(
                    label: '${pendingRequests.length} Menunggu',
                    color: AppColors.warningAmber,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: '${approvedRequests.length} Diterima',
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: '${rejectedRequests.length} Ditolak',
                    color: AppColors.alertCoral,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            if (state.isApplicationHistoryLoading) ...[
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.borderLight,
              ),
              const SizedBox(height: 12),
            ],
            if (state.applicationHistoryError != null) ...[
              _ErrorBanner(message: state.applicationHistoryError!),
              const SizedBox(height: 12),
            ],

            if (state.applicationHistory.isEmpty)
              _EmptyHistoryCard()
            else ...[
              if (pendingRequests.isNotEmpty) ...[
                SectionHeader(
                  title: 'Sedang Diajukan',
                  subtitle: '${pendingRequests.length} ajuan',
                ),
                const SizedBox(height: 10),
                ...pendingRequests.map((item) => _ApplicationCard(item: item)),
                const SizedBox(height: 20),
              ],
              if (approvedRequests.isNotEmpty) ...[
                SectionHeader(
                  title: 'Diterima',
                  subtitle: '${approvedRequests.length} ajuan',
                ),
                const SizedBox(height: 10),
                ...approvedRequests
                    .map((item) => _ApplicationCard(item: item)),
                const SizedBox(height: 20),
              ],
              if (rejectedRequests.isNotEmpty) ...[
                SectionHeader(
                  title: 'Ditolak',
                  subtitle: '${rejectedRequests.length} ajuan',
                ),
                const SizedBox(height: 10),
                ...rejectedRequests
                    .map((item) => _ApplicationCard(item: item)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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

class _EmptyHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 28,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada ajuan',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Ajukan bergabung dari halaman detail tim, lalu riwayatnya muncul di sini.',
            style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.item});
  final ApplicationHistoryItem item;

  Color get _statusColor {
    if (item.status == 'Diterima') return AppColors.successGreen;
    if (item.status == 'Ditolak') return AppColors.alertCoral;
    return AppColors.warningAmber;
  }

  Color get _statusBg {
    if (item.status == 'Diterima') return AppColors.successGreenLight;
    if (item.status == 'Ditolak') return AppColors.alertCoralLight;
    return AppColors.warningAmberLight;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.teamName, style: AppTextStyles.subtitle),
                      const SizedBox(height: 3),
                      Text(item.competitionName, style: AppTextStyles.muted),
                    ],
                  ),
                ),
                SkillChip(
                  label: item.status,
                  backgroundColor: _statusBg,
                  textColor: _statusColor,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.work_outline_rounded,
                  size: 14,
                  color: AppColors.textGray,
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.matchingScore}% match',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: item.matchingScore / 100,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(item.createdLabel, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Lihat Tim',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamDetailScreen(teamId: item.teamId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}