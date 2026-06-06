import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.border,
    this.elevation = 0,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Border? border;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final bg = color ?? AppColors.backgroundCard;
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    return Material(
      color: bg,
      borderRadius: radius,
      elevation: elevation,
      shadowColor: AppColors.deepNavy.withAlpha(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.primaryBlue.withAlpha(10),
        highlightColor: AppColors.primaryBlue.withAlpha(6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: color != null
                      ? Colors.transparent
                      : AppColors.borderLight,
                  width: 1,
                ),
          ),
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}