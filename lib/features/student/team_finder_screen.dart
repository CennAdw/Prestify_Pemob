import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/team_model.dart';
import 'lecturer_finder_screen.dart';
import 'team_detail_screen.dart';

class TeamFinderScreen extends StatefulWidget {
  const TeamFinderScreen({super.key});

  @override
  State<TeamFinderScreen> createState() => _TeamFinderScreenState();
}

class _TeamFinderScreenState extends State<TeamFinderScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final categories = const ['Semua', 'GEMASTIK', 'LIDM', 'Data'];
    final query = _searchController.text.toLowerCase();
    final filteredTeams = state.teams.where((team) {
      final matchesQuery =
          team.name.toLowerCase().contains(query) ||
          team.competitionName.toLowerCase().contains(query) ||
          team.requiredSkills.any(
            (skill) => skill.toLowerCase().contains(query),
          );
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          team.competitionName.toLowerCase().contains(
            _selectedCategory.toLowerCase(),
          );
      return matchesQuery && matchesCategory;
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Cari Tim', style: AppTextStyles.headline),
                ),
                IconButton(
                  tooltip: 'Cari dosen pembimbing',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LecturerFinderScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.co_present_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Open recruitment tim lomba yang cocok dengan skill kamu.',
              style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari nama tim, lomba, atau skill',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  selectedColor: AppColors.primaryBlue,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Open Recruitment'),
            const SizedBox(height: 10),
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
            if (filteredTeams.isEmpty)
              CustomCard(
                child: Text(
                  'Tidak ada tim yang cocok dengan pencarian.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                ),
              )
            else
              ...filteredTeams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TeamCard(team: team),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  team.name,
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),
              SkillChip(
                label: team.status,
                backgroundColor: AppColors.successGreen.withAlpha(28),
                textColor: AppColors.successGreen,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            team.competitionName,
            style: AppTextStyles.body.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: team.requiredSkills
                .map((skill) => SkillChip(label: skill, compact: true))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.groups_rounded,
                  label: '${team.currentMembers}/${team.maxMembers} anggota',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  icon: Icons.schedule_rounded,
                  label: team.deadline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Skill matching score',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${team.matchingScore}%',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: team.matchingScore / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: AppColors.lightBlue,
            color: _scoreColor(team.matchingScore),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Detail',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamDetailScreen(teamId: team.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.successGreen;
    if (score >= 60) return AppColors.accentYellow;
    return AppColors.secondaryBlue;
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoftGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondaryBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
