import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                iconOutlined: Icons.home_outlined,
                label: 'Beranda',
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.groups_rounded,
                iconOutlined: Icons.groups_outlined,
                label: 'Tim',
                selected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _NavItemCreate(
                selected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                icon: Icons.inbox_rounded,
                iconOutlined: Icons.inbox_outlined,
                label: 'Ajuan',
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                iconOutlined: Icons.person_outlined,
                label: 'Profil',
                selected: selectedIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconOutlined;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryBlue.withAlpha(18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? icon : iconOutlined,
                size: 22,
                color: selected ? AppColors.primaryBlue : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primaryBlue : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemCreate extends StatelessWidget {
  const _NavItemCreate({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.deepNavy : AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primaryBlue.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 22,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Posting',
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primaryBlue : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}