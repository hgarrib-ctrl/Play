import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final VoidCallback? onAddCategory;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + (onAddCategory != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            // Add Category Chip
            return GestureDetector(
              onTap: onAddCategory,
              child: ClipRRect(
                borderRadius: AppStyles.borderRadiusSmall,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                      borderRadius: AppStyles.borderRadiusSmall,
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: isDark ? AppColors.electricBlue : AppColors.electricBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.electricBlue : AppColors.electricBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final cat = categories[index];
          final isSelected = cat == selectedCategory;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
                borderRadius: AppStyles.borderRadiusSmall,
                border: Border.all(
                  color: isSelected
                      ? AppColors.electricBlue
                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected ? AppStyles.glowShadowBlue : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
