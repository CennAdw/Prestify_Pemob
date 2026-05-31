import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const headline = TextStyle(
    color: AppColors.textDark,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );

  static const title = TextStyle(
    color: AppColors.textDark,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const subtitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const body = TextStyle(
    color: AppColors.textDark,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const muted = TextStyle(
    color: AppColors.textGray,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const small = TextStyle(
    color: AppColors.textGray,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}
