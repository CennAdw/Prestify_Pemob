import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SkillChip extends StatelessWidget {
  const SkillChip({
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.lightBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 13 : 15,
              color: textColor ?? AppColors.primaryBlue,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor ?? AppColors.primaryBlue,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
