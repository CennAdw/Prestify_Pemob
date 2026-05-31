import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color = AppColors.white,
    this.border,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final decorated = Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepNavy.withAlpha(14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return decorated;
  }
}
