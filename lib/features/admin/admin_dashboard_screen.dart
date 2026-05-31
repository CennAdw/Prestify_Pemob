import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/competition_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadAdminDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final statColumns = width >= 620 ? 4 : 2;
    final statIcons = const {
      'Total Mahasiswa': Icons.school_rounded,
      'Total Tim': Icons.groups_rounded,
      'Total Lomba': Icons.emoji_events_rounded,
      'Dosen Aktif': Icons.co_present_rounded,
    };
    final maxCategoryCount = state.categoryStats.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (_) => false,
            ),
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
                    'Dashboard Admin',
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rumah Prestasi UPI',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.lightBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (state.isAdminLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.adminError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.adminError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            GridView.count(
              crossAxisCount: statColumns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: width >= 620 ? 1.35 : 1.18,
              children: state.adminStats.entries
                  .map(
                    (entry) => _StatCard(
                      label: entry.key,
                      value: entry.value.toString(),
                      icon: statIcons[entry.key] ?? Icons.analytics_rounded,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Aktivitas Platform'),
            const SizedBox(height: 10),
            CustomCard(
              child: Column(
                children: state.categoryStats.entries.map((entry) {
                  final index = state.categoryStats.keys.toList().indexOf(
                    entry.key,
                  );
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == state.categoryStats.length - 1 ? 0 : 14,
                    ),
                    child: _ActivityBar(
                      label: entry.key,
                      value: entry.value / maxCategoryCount,
                      count: entry.value.toString(),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Postingan Terbaru'),
            const SizedBox(height: 10),
            ...state.posts
                .take(3)
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SkillChip(label: post.type, compact: true),
                              const Spacer(),
                              Text(
                                post.createdLabel,
                                style: AppTextStyles.small,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(post.title, style: AppTextStyles.subtitle),
                          const SizedBox(height: 4),
                          Text(
                            post.description,
                            style: AppTextStyles.muted,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Lomba Menunggu Verifikasi'),
            const SizedBox(height: 10),
            ...state.pendingCompetitions.map(
              (competition) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompetitionReviewCard(competition: competition),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 21),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              Text(
                label,
                style: AppTextStyles.small,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.label,
    required this.value,
    required this.count,
  });

  final String label;
  final double value;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body)),
            Text(
              count,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 10,
          borderRadius: BorderRadius.circular(99),
          backgroundColor: AppColors.lightBlue,
          color: AppColors.primaryBlue,
        ),
      ],
    );
  }
}

class _CompetitionReviewCard extends StatelessWidget {
  const _CompetitionReviewCard({required this.competition});

  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isPending = competition.status == 'Menunggu Verifikasi';

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(competition.name, style: AppTextStyles.subtitle),
              ),
              SkillChip(
                label: competition.status,
                backgroundColor: isPending
                    ? AppColors.accentYellow.withAlpha(48)
                    : AppColors.successGreen.withAlpha(28),
                textColor: isPending
                    ? AppColors.deepNavy
                    : AppColors.successGreen,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${competition.category} - Deadline ${competition.deadline}',
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: isPending ? 'Verifikasi' : 'Terverifikasi',
            icon: isPending ? Icons.verified_outlined : Icons.verified_rounded,
            onPressed: isPending
                ? () async {
                    final message = await state.verifyCompetitionApi(
                      competition.id,
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
    );
  }
}
