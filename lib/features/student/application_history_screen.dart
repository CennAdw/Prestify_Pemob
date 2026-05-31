import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';

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

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.loadApplicationHistory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Riwayat Ajuan', style: AppTextStyles.headline),
                ),
                IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: state.loadApplicationHistory,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pantau status pengajuan bergabung ke tim lomba.',
              style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Ajuan Cari Tim'),
            const SizedBox(height: 10),
            if (state.isApplicationHistoryLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.applicationHistoryError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.applicationHistoryError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (state.applicationHistory.isEmpty)
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Belum ada ajuan',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ajukan bergabung dari halaman detail tim, lalu riwayatnya muncul di sini.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...state.applicationHistory.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.teamName,
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                            SkillChip(
                              label: item.status,
                              backgroundColor: AppColors.accentYellow.withAlpha(
                                48,
                              ),
                              textColor: AppColors.deepNavy,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.competitionName, style: AppTextStyles.muted),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.appliedRole,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${item.matchingScore}% match',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: item.matchingScore / 100,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(99),
                          backgroundColor: AppColors.lightBlue,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(height: 8),
                        Text(item.createdLabel, style: AppTextStyles.small),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
