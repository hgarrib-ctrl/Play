import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/calculator_controller.dart';
import '../controllers/billing_controller.dart';
import '../services/currency_service.dart';

class CalculatorPanel extends StatelessWidget {
  final CalculatorController calcController;
  final BillingController billingController;
  final VoidCallback? onClose;

  const CalculatorPanel({
    super.key,
    required this.calcController,
    required this.billingController,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: calcController,
      builder: (context, _) {
        final isIndependent = calcController.mode == CalculatorMode.independent;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xF2080D19) : const Color(0xF7FFFFFF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  width: 1,
                ),
                boxShadow: AppStyles.subtleShadowDark,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Mode Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mode Selector Segmented Tabs
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            _modeTab(
                              title: 'Independent',
                              icon: Icons.calculate,
                              isActive: isIndependent,
                              onTap: () => calcController.setMode(CalculatorMode.independent),
                              isDark: isDark,
                            ),
                            _modeTab(
                              title: 'Bill Adjustment',
                              icon: Icons.tune,
                              isActive: !isIndependent,
                              onTap: () => calcController.setMode(CalculatorMode.billAdjustment),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      if (onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          onPressed: onClose,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Display Area (Glass screen)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
                      borderRadius: AppStyles.borderRadiusMedium,
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Expression
                        Text(
                          calcController.expression,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Live Result
                        Text(
                          calcController.result,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bill Adjustment Action Bar (Mode B only)
                  if (!isIndependent) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.1),
                        borderRadius: AppStyles.borderRadiusSmall,
                        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Current Result: ${CurrencyService.format(calcController.numericResult)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                              ),
                            ),
                          ),
                          // Apply Discount
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emeraldGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                            label: const Text('Discount', style: TextStyle(color: Colors.white, fontSize: 11)),
                            onPressed: calcController.numericResult > 0
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    billingController.applyDiscount(calcController.numericResult);
                                    if (onClose != null) onClose!();
                                  }
                                : null,
                          ),
                          const SizedBox(width: 6),
                          // Apply Charge
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.electricBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add, size: 14, color: Colors.white),
                            label: const Text('Charge', style: TextStyle(color: Colors.white, fontSize: 11)),
                            onPressed: calcController.numericResult > 0
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    billingController.applyAdditionalCharge(calcController.numericResult);
                                    if (onClose != null) onClose!();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Keypad Grid: 4 x 4
                  Column(
                    children: [
                      _keypadRow(['7', '8', '9', '÷'], isDark),
                      const SizedBox(height: 8),
                      _keypadRow(['4', '5', '6', '×'], isDark),
                      const SizedBox(height: 8),
                      _keypadRow(['1', '2', '3', '−'], isDark),
                      const SizedBox(height: 8),
                      _keypadRow(['C', '0', '⌫', '+'], isDark),
                      const SizedBox(height: 8),
                      // Equals Row
                      Row(
                        children: [
                          Expanded(
                            child: _calcKey('.', isDark, onTap: () => calcController.input('.')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                calcController.calculate();
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: AppStyles.borderRadiusMedium,
                                  boxShadow: AppStyles.glowShadowBlue,
                                ),
                                child: const Center(
                                  child: Text(
                                    '=',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _modeTab({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.glassFillActiveDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive ? AppStyles.subtleShadowDark : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? AppColors.electricBlue
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keypadRow(List<String> keys, bool isDark) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _calcKey(
              key,
              isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                if (key == 'C') {
                  calcController.clear();
                } else if (key == '⌫') {
                  calcController.backspace();
                } else {
                  calcController.input(key);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _calcKey(String label, bool isDark, {required VoidCallback onTap}) {
    final isOperator = label == '+' || label == '−' || label == '×' || label == '÷';
    final isSpecial = label == 'C' || label == '⌫';

    Color bgColor = isDark ? AppColors.glassFillDark : AppColors.glassFillLight;
    Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    if (isOperator) {
      bgColor = isDark ? const Color(0x33638BFF) : const Color(0x22638BFF);
      textColor = AppColors.electricBlue;
    } else if (isSpecial) {
      textColor = AppColors.coralRed;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppStyles.borderRadiusMedium,
          border: Border.all(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isOperator || isSpecial ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
