import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/anggota_post_model.dart';
import '../../data/models/team_model.dart';
import 'lecturer_finder_screen.dart';
import 'team_detail_screen.dart';

Future<void> _launchPortfolioUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL portfolio tidak valid.')),
    );
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka URL portfolio.')),
    );
  }
}

class TeamFinderScreen extends StatefulWidget {
  const TeamFinderScreen({super.key});

  @override
  State<TeamFinderScreen> createState() => _TeamFinderScreenState();
}

class _TeamFinderScreenState extends State<TeamFinderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _cariTimSearchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppStateScope.of(context);
      state.loadTeams();
      state.loadAnggotaPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _cariTimSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cari Tim', style: AppTextStyles.headline),
                      Text(
                        'Temukan tim atau anggota yang kamu butuhkan.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderFocus),
                  ),
                  child: IconButton(
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
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // TabBar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textGray,
              indicator: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Cari Anggota'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Cari Tim'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CariAnggotaTab(
                  searchController: _searchController,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (cat) =>
                      setState(() => _selectedCategory = cat),
                ),
                _CariTimTab(
                  searchController: _cariTimSearchController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Cari Anggota (list tim open recruitment) ────────────────────────

class _CariAnggotaTab extends StatefulWidget {
  const _CariAnggotaTab({
    required this.searchController,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  State<_CariAnggotaTab> createState() => _CariAnggotaTabState();
}

class _CariAnggotaTabState extends State<_CariAnggotaTab> {
  final _categories = const ['Semua', 'GEMASTIK', 'LIDM', 'PKM', 'P2MW'];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = widget.searchController.text.toLowerCase();
    final studentSkills =
        state.student.skills.map((s) => s.toLowerCase()).toSet();

    final filteredTeams = state.teams.where((team) {
      final matchesQuery = team.name.toLowerCase().contains(query) ||
          team.competitionName.toLowerCase().contains(query) ||
          team.requiredSkills
              .any((skill) => skill.toLowerCase().contains(query));
      final matchesCategory = widget.selectedCategory == 'Semua' ||
          team.competitionName
              .toLowerCase()
              .contains(widget.selectedCategory.toLowerCase());
      return matchesQuery && matchesCategory;
    }).toList();

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      backgroundColor: Colors.white,
      onRefresh: () async {
        // Refresh data tim
        await state.loadTeams();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Search bar
          _SearchBar(
            controller: widget.searchController,
            hint: 'Cari nama tim, lomba, atau skill...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final selected = category == widget.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => widget.onCategoryChanged(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        category,
                        style: AppTextStyles.smallMedium.copyWith(
                          color:
                              selected ? AppColors.white : AppColors.textBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 22),
          SectionHeader(
            title: 'Open Recruitment',
            subtitle: '${filteredTeams.length} tim tersedia',
          ),
          const SizedBox(height: 12),

          if (state.isTeamsLoading) ...[
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.borderLight,
            ),
            const SizedBox(height: 12),
          ],
          if (state.teamError != null) ...[
            _ErrorBanner(message: state.teamError!),
            const SizedBox(height: 12),
          ],
          if (filteredTeams.isEmpty)
            const _EmptyState(message: 'Tidak ada tim yang cocok dengan pencarian.')
          else
            ...filteredTeams.map(
              (team) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TeamCard(team: team, studentSkills: studentSkills),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab 2: Cari Tim (list postingan individu) ──────────────────────────────

class _CariTimTab extends StatefulWidget {
  const _CariTimTab({required this.searchController});
  final TextEditingController searchController;

  @override
  State<_CariTimTab> createState() => _CariTimTabState();
}

class _CariTimTabState extends State<_CariTimTab> {
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = widget.searchController.text.toLowerCase();

    final filteredPosts = state.anggotaPosts.where((post) {
      return post.title.toLowerCase().contains(query) ||
          post.studentName.toLowerCase().contains(query) ||
          post.competitionName.toLowerCase().contains(query) ||
          post.skills.any((s) => s.toLowerCase().contains(query));
    }).toList();

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      backgroundColor: Colors.white,
      onRefresh: () async {
        // Refresh data postingan pencarian anggota/tim
        await state.loadAnggotaPosts();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SearchBar(
            controller: widget.searchController,
            hint: 'Cari nama, skill, atau lomba...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Mencari Tim',
            subtitle: '${filteredPosts.length} postingan',
          ),
          const SizedBox(height: 12),

          if (state.isAnggotaPostsLoading) ...[
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.borderLight,
            ),
            const SizedBox(height: 12),
          ],
          if (state.anggotaPostError != null) ...[
            _ErrorBanner(message: state.anggotaPostError!),
            const SizedBox(height: 12),
          ],
          if (filteredPosts.isEmpty)
            const _EmptyState(
              message: 'Belum ada postingan yang mencari tim.',
            )
          else
            ...filteredPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AnggotaPostCard(post: post),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGray),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textGray, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

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
          Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Card: Tim (Cari Anggota tab) ───────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.studentSkills});

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
                    Text(
                      team.name,
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      team.competitionName,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SkillChip(
                label: team.status,
                backgroundColor: AppColors.successGreenLight,
                textColor: AppColors.successGreen,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: team.requiredSkills
                .map((skill) => SkillChip(label: skill, compact: true))
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoPill(
                icon: Icons.groups_rounded,
                label: '${team.currentMembers}/${team.maxMembers} anggota',
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: team.deadline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Skill match',
                  style:
                      AppTextStyles.small.copyWith(color: AppColors.textGray),
                ),
              ),
              Text(
                '$score%',
                style: AppTextStyles.subtitle.copyWith(color: scoreColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 7,
              backgroundColor: AppColors.borderLight,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Lihat Detail',
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
}

// ── Card: Postingan Individu (Cari Tim tab) ────────────────────────────────

class _AnggotaPostCard extends StatelessWidget {
  const _AnggotaPostCard({required this.post});
  final AnggotaPostModel post;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nama + status
          Row(
            children: [
              _ProfileAvatar(
                avatarUrl: null,
                name: post.studentName,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.studentName.isEmpty ? '-' : post.studentName,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      post.competitionName,
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
              SkillChip(
                label: post.status,
                backgroundColor: AppColors.successGreenLight,
                textColor: AppColors.successGreen,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Judul
          Text(post.title, style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 6),

          // Deskripsi
          Text(
            post.description,
            style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Skills
          if (post.skills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.skills
                  .map((skill) => SkillChip(label: skill, compact: true))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Portfolio — buka URL langsung
          if (post.portfolioUrl != null && post.portfolioUrl!.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _launchPortfolioUrl(context, post.portfolioUrl!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Buka Portofolio'),
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style:
                    AppTextStyles.small.copyWith(color: AppColors.textBody),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared avatar widget ───────────────────────────────────────────────────

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