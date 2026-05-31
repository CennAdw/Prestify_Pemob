import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepNavy,
              AppColors.primaryBlue,
              AppColors.secondaryBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white.withAlpha(60)),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'UPI Connect+',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Rumah Prestasi UPI',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Temukan Tim, Bangun Prestasi.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Mulai',
                  icon: Icons.arrow_forward_rounded,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryBlue,
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
