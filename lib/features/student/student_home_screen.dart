import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/team_model.dart';
import 'lecturer_finder_screen.dart';
import 'team_detail_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({required this.onNavigate, super.key});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final student = state.student;
    final studentSkills =
        student.skills.map((s) => s.toLowerCase()).toSet();
    final recommendedTeams = state.teams.take(2).toList();
    final popularCompetitions = state.competitions.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientMid,
                  ],
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
                          Container(
                            width: 32,
                            height: 32,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/prestify_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prestify',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white.withAlpha(220),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
                      const SizedBox(height: 24),
                      Text(
                        'Halo, ${student.name.split(' ').take(2).join(' ')}',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        student.nim != null
                            ? 'NIM ${student.nim} · ${student.program ?? ''}'
                            : 'Temukan tim dan peluang terbaik',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.white.withAlpha(180),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      // Quick stats row
                      Row(
                        children: [
                          _StatPill(
                            label: '${student.skills.length} Skill',
                            icon: Icons.auto_awesome_rounded,
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            label: '${recommendedTeams.length} Rekomendasi Tim',
                            icon: Icons.groups_rounded,
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
                  // Loading/error banners
                  if (state.isTeamsLoading || state.isCompetitionsLoading) ...[
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.primaryBlue,
                      backgroundColor: AppColors.borderLight,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.apiNotice != null ||
                      state.teamError != null ||
                      state.competitionError != null) ...[
                    _InfoBanner(
                      text: state.apiNotice ??
                          state.teamError ??
                          state.competitionError ??
                          '',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Shortcuts grid
                  _ShortcutGrid(onNavigate: onNavigate),
                  const SizedBox(height: 24),

                  // Skills card
                  if (student.skills.isNotEmpty) ...[
                    CustomCard(
                      color: AppColors.deepNavy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.accentYellow,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Profil Skill Kamu',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: student.skills
                                .map(
                                  (skill) => SkillChip(
                                    label: skill,
                                    backgroundColor:
                                        AppColors.white.withAlpha(24),
                                    textColor: AppColors.white,
                                    compact: true,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Recommended teams
                  SectionHeader(
                    title: 'Rekomendasi Tim',
                    actionLabel: 'Lihat semua',
                    onAction: () => onNavigate(1),
                  ),
                  const SizedBox(height: 12),
                  if (recommendedTeams.isEmpty)
                    _EmptyState(
                      icon: Icons.groups_outlined,
                      message: 'Belum ada tim tersedia',
                    )
                  else
                    ...recommendedTeams.map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecommendedTeamCard(
                          team: team,
                          studentSkills: studentSkills,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  // Popular competitions
                  const SectionHeader(title: 'Lomba Populer'),
                  const SizedBox(height: 12),
                  ...popularCompetitions.map(
                    (competition) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.accentYellow,
                                    Color(0xFFEF9F27),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    competition.name,
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${competition.category} · ${competition.interestCount} peminat',
                                    style: AppTextStyles.small,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateMatchingScore(TeamModel team, Set<String> studentSkills) {
    if (team.requiredSkills.isEmpty) return 0;
    final matchedCount = team.requiredSkills
        .where((skill) => studentSkills.contains(skill.toLowerCase()))
        .length;
    return ((matchedCount / team.requiredSkills.length) * 100).round();
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white.withAlpha(200)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.white.withAlpha(220),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderFocus),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryBlue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.small.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RecommendedTeamCard extends StatelessWidget {
  const _RecommendedTeamCard({
    required this.team,
    required this.studentSkills,
  });

  final TeamModel team;
  final Set<String> studentSkills;

  int get score {
    if (team.requiredSkills.isEmpty) return 0;
    final matched = team.requiredSkills
        .where((s) => studentSkills.contains(s.toLowerCase()))
        .length;
    return ((matched / team.requiredSkills.length) * 100).round();
  }

  Color get scoreColor {
    if (score >= 75) return AppColors.successGreen;
    if (score >= 50) return AppColors.warningAmber;
    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamDetailScreen(teamId: team.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(team.name, style: AppTextStyles.subtitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score% match',
                  style: AppTextStyles.small.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            team.competitionName,
            style: AppTextStyles.muted,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _ShortcutItem(
        'Cari Tim',
        Icons.groups_rounded,
        const Color(0xFFEFF6FF),
        AppColors.primaryBlue,
        () => onNavigate(1),
      ),
      _ShortcutItem(
        'Cari Lomba',
        Icons.emoji_events_rounded,
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
        () => onNavigate(1),
      ),
      _ShortcutItem(
        'Dosen Pembimbing',
        Icons.co_present_rounded,
        const Color(0xFFD1FAE5),
        AppColors.successGreen,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LecturerFinderScreen()),
        ),
      ),
      _ShortcutItem(
        'Portofolio',
        Icons.badge_rounded,
        const Color(0xFFFCE7F3),
        const Color(0xFFBE185D),
        () => onNavigate(4),
      ),
    ];

    return GridView.builder(
      itemCount: shortcuts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = shortcuts[index];
        return CustomCard(
          onTap: item.onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              Text(
                item.label,
                style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem(
    this.label,
    this.icon,
    this.iconBg,
    this.iconColor,
    this.onTap,
  );

  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
}