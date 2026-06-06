import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class SkillChip extends StatelessWidget {
  const SkillChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.compact = false,
    this.icon,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceElevated;
    final fg = textColor ?? AppColors.primaryBlue;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fg.withAlpha(30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: (compact ? AppTextStyles.small : AppTextStyles.smallMedium)
                .copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}