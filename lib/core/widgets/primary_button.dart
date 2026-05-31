import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
    this.backgroundColor,
    this.foregroundColor,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, maxLines: 1),
        ],
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final child = outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: foregroundColor ?? AppColors.primaryBlue,
              side: BorderSide(color: foregroundColor ?? AppColors.primaryBlue),
              shape: shape,
            ),
            child: content,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: backgroundColor ?? AppColors.primaryBlue,
              foregroundColor: foregroundColor ?? AppColors.white,
              disabledBackgroundColor: AppColors.softBorder,
              disabledForegroundColor: AppColors.textGray,
              elevation: 0,
              shape: shape,
            ),
            child: content,
          );

    return SizedBox(width: isExpanded ? double.infinity : null, child: child);
  }
}
