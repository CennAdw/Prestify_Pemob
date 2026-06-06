import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.outlined = false,
    this.isExpanded = true,
    this.backgroundColor,
    this.foregroundColor,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (outlined ? Colors.transparent : AppColors.primaryBlue);
    final effectiveFg = foregroundColor ??
        (outlined ? AppColors.primaryBlue : AppColors.white);

    final vertPad = compact ? 10.0 : 14.0;
    final horizPad = compact ? 16.0 : 20.0;

    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: effectiveFg,
            side: BorderSide(color: effectiveFg.withAlpha(200), width: 1.5),
            padding: EdgeInsets.symmetric(
              vertical: vertPad,
              horizontal: horizPad,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.buttonLabel,
          )
        : ElevatedButton.styleFrom(
            backgroundColor: effectiveBg,
            foregroundColor: effectiveFg,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(
              vertical: vertPad,
              horizontal: horizPad,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.buttonLabel,
          );

    Widget buttonChild = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 16 : 18),
              SizedBox(width: compact ? 6 : 8),
              Text(label),
            ],
          )
        : Text(label);

    if (isExpanded) {
      buttonChild = SizedBox(
        width: double.infinity,
        child: buttonChild,
      );
    }

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: buttonChild,
    );
  }
}