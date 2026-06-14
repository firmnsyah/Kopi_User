import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class FilterChipBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const FilterChipBtn({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: active
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            size: 13,
            weight: FontWeight.w600,
            color: active ? Colors.white : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
