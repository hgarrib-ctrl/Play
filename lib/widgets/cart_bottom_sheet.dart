import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/billing_controller.dart';
import '../models/bill_item.dart';
import '../services/currency_service.dart';
import 'glass_button.dart';
import 'glass_text_field.dart';

class CartBottomSheet extends StatelessWidget {
  final BillingController billingController;
  final VoidCallback onOpenCalculator;
  final VoidCallback onCompleteBill;
  final VoidCallback? onOpenExchange;

  const CartBottomSheet({
    super.key,
    required this.billingController,
    required this.onOpenCalculator,
    required this.onCompleteBill,
    this.onOpenExchange,
  });

  void _showPriceOverrideDialog(BuildContext context, int index, BillItem item) {
    final controller = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Override Price for ${item.productName}',
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original Price: ${CurrencyService.format(item.originalPrice)}',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: controller,
                labelText: 'Bill Unit Price (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
              ),
              onPressed: () {
                final newPrice = double.tryParse(controller.text.trim());
                if (newPrice != null && newPrice >= 0) {
                  billingController.overrideItemPrice(index, newPrice);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddChargeDialog(BuildContext context, {required bool isDiscount}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            isDiscount ? 'Add Discount' : 'Add Additional Charge',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: GlassTextField(
            controller: controller,
            labelText: isDiscount ? 'Discount Amount (₹)' : 'Charge Amount (₹)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDiscount ? AppColors.emeraldGreen : AppColors.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
              ),
              onPressed: () {
                final val = double.tryParse(controller.text.trim());
                if (val != null && val >= 0) {
                  if (isDiscount) {
                    billingController.applyDiscount(val);
                  } else {
                    billingController.applyAdditionalCharge(val);
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = billingController.items;
    final isExchange = billingController.isExchangeMode;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE6080D19) : const Color(0xF2FFFFFF),
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
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          isExchange ? 'Exchange Bill' : 'Current Bill',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.glassFillActiveDark : AppColors.glassFillActiveLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${billingController.itemCount} items',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Undo Button
                        if (billingController.canUndo)
                          IconButton(
                            icon: const Icon(Icons.undo, size: 20),
                            color: AppColors.softCyan,
                            tooltip: 'Undo',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              billingController.undo();
                            },
                          ),
                        // Clear Bill Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.coralRed,
                          tooltip: 'Clear Bill',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                final dialogDark = Theme.of(ctx).brightness == Brightness.dark;
                                return AlertDialog(
                                  backgroundColor: dialogDark ? AppColors.darkSurface : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
                                  title: Text(
                                    'Clear Bill?',
                                    style: TextStyle(
                                      color: dialogDark ? Colors.white : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to discard all items in the current bill?',
                                    style: TextStyle(
                                      color: dialogDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(
                                        'Keep',
                                        style: TextStyle(
                                          color: dialogDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.coralRed,
                                        shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                                      ),
                                      onPressed: () {
                                        billingController.clearBill();
                                        Navigator.pop(ctx);
                                        Navigator.pop(context); // close sheet
                                      },
                                      child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white12),

              // Items List
              if (items.isEmpty && (!isExchange || billingController.returnedItemValue <= 0))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 48,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bill is empty',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap products above to add items',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  GestureDetector(
                                    onTap: () => _showPriceOverrideDialog(context, index, item),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${CurrencyService.format(item.unitPrice, showDecimals: false)} × ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.hasPriceOverride
                                                ? AppColors.amberOrange
                                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                            fontWeight: item.hasPriceOverride ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                        if (item.hasPriceOverride) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit, size: 12, color: AppColors.amberOrange),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Total for item
                            Text(
                              CurrencyService.format(item.itemTotal, showDecimals: false),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Minus Button
                            _qtyButton(
                              icon: Icons.remove,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                billingController.decrementQuantity(index);
                              },
                              isDark: isDark,
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),

                            // Plus Button
                            _qtyButton(
                              icon: Icons.add,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                billingController.incrementQuantity(index);
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Exchange valuation summary if active
              if (isExchange && billingController.returnedItemValue > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amberOrange.withValues(alpha: 0.12),
                    borderRadius: AppStyles.borderRadiusSmall,
                    border: Border.all(color: AppColors.amberOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, size: 16, color: AppColors.amberOrange),
                          const SizedBox(width: 6),
                          Text(
                            'Returned Item Value: ${CurrencyService.format(billingController.returnedItemValue)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.amberOrange,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.amberOrange),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => billingController.setReturnedItemDetails(value: 0.0),
                      ),
                    ],
                  ),
                ),

              // Quick Actions: Discount / Charge / Calculator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    // Exchange Chip
                    ActionChip(
                      backgroundColor: isExchange
                          ? AppColors.amberOrange.withValues(alpha: 0.25)
                          : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
                      label: Text(
                        isExchange ? 'Exchange ON' : '+ Exchange',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isExchange ? AppColors.amberOrange : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                      onPressed: () {
                        if (onOpenExchange != null) {
                          onOpenExchange!();
                        } else {
                          billingController.toggleExchangeMode(!isExchange);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // Discount Chip
                    ActionChip(
                      backgroundColor: billingController.discountAmount > 0
                          ? AppColors.emeraldGreen.withValues(alpha: 0.2)
                          : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
                      label: Text(
                        billingController.discountAmount > 0
                            ? 'Disc: -${CurrencyService.format(billingController.discountAmount, showDecimals: false)}'
                            : '+ Disc',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: billingController.discountAmount > 0
                              ? AppColors.emeraldGreen
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                      onPressed: () => _showAddChargeDialog(context, isDiscount: true),
                    ),
                    const SizedBox(width: 8),
                    // Charge Chip
                    ActionChip(
                      backgroundColor: billingController.additionalCharge > 0
                          ? AppColors.electricBlue.withValues(alpha: 0.2)
                          : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
                      label: Text(
                        billingController.additionalCharge > 0
                            ? 'Chg: +${CurrencyService.format(billingController.additionalCharge, showDecimals: false)}'
                            : '+ Chg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: billingController.additionalCharge > 0
                              ? AppColors.electricBlue
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                      onPressed: () => _showAddChargeDialog(context, isDiscount: false),
                    ),
                    const Spacer(),
                    // Open Calculator button
                    IconButton(
                      icon: const Icon(Icons.calculate_outlined, color: AppColors.softCyan),
                      tooltip: 'Calculator',
                      onPressed: onOpenCalculator,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white12),

              // Bottom Total & Complete Action
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExchange
                              ? (billingController.isRefundable
                                  ? 'OWED TO CUSTOMER'
                                  : 'CUSTOMER PAYS')
                              : 'TOTAL PAYABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isExchange
                                ? (billingController.isRefundable
                                    ? AppColors.amberOrange
                                    : AppColors.emeraldGreen)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                        Text(
                          CurrencyService.format(billingController.finalTotal),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: billingController.isRefundable
                                ? AppColors.amberOrange
                                : (isDark ? AppColors.emeraldGreen : const Color(0xFF0F9D58)),
                          ),
                        ),
                      ],
                    ),

                    // Generate Bill Button (Speed First)
                    GlassButton(
                      text: 'Generate Bill',
                      icon: Icons.receipt_long,
                      variant: GlassButtonVariant.success,
                      onPressed: (items.isNotEmpty || (isExchange && billingController.returnedItemValue > 0))
                          ? onCompleteBill
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassFillActiveDark : AppColors.glassFillActiveLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
