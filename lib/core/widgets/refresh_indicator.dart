import 'package:flutter/material.dart';
import '../constants/app_colors.dart'; // Sesuaikan import warna kamu

class CommonRefreshIndicator extends StatelessWidget {
  const CommonRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryBlue, // Warna spinner global aplikasi kamu
      onRefresh: onRefresh,
      child: child is SingleChildScrollView
          ? child // Jika sudah SingleChildScrollView, langsung return
          : SingleChildScrollView(
              // Jika bukan, otomatis dibungkus biar bisa di-pull down walau data kosong
              physics: const AlwaysScrollableScrollPhysics(),
              child: child,
            ),
    );
  }
}