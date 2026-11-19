import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/billing_controller.dart';
import '../services/currency_service.dart';
import 'glass_text_field.dart';

class ExchangePanel extends StatefulWidget {
  final BillingController billingController;
  final VoidCallback? onDismiss;

  const ExchangePanel({
    super.key,
    required this.billingController,
    this.onDismiss,
  });

  @override
  State<ExchangePanel> createState() => _ExchangePanelState();
}

class _ExchangePanelState extends State<ExchangePanel> {
  late TextEditingController _valueController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final val = widget.billingController.returnedItemValue;
    _valueController = TextEditingController(text: val > 0 ? val.toStringAsFixed(0) : '');
    _notesController = TextEditingController(text: widget.billingController.returnedItemNotes ?? '');
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyValuation() {
    final val = double.tryParse(_valueController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();
    widget.billingController.setReturnedItemDetails(
      value: val,
      notes: notes.isNotEmpty ? notes : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = widget.billingController.subtotal;
    final returnedVal = widget.billingController.returnedItemValue;
    final isRefundable = widget.billingController.isRefundable;
    final finalDiff = widget.billingController.finalTotal;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF2080D19) : const Color(0xF7FFFFFF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.amberOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz, color: AppColors.amberOrange, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Exchange / Return Mode',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Inputs for Returned Item
              GlassTextField(
                controller: _valueController,
                labelText: 'Returned Item Valuation (₹)',
                hintText: 'e.g. 700',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee,
                onChanged: (_) => _applyValuation(),
              ),

              const SizedBox(height: 10),

              GlassTextField(
                controller: _notesController,
                labelText: 'Returned Item Description / Notes',
                hintText: 'e.g. Old Steel Dinner Set (Damaged box)',
                prefixIcon: Icons.edit_note,
                onChanged: (_) => _applyValuation(),
              ),

              const SizedBox(height: 16),

              // Breakdown Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
                  borderRadius: AppStyles.borderRadiusMedium,
                  border: Border.all(
                    color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  ),
                ),
                child: Column(
                  children: [
                    _calcRow(
                      'New Products Purchased (+)',
                      CurrencyService.format(subtotal),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _calcRow(
                      'Returned Item Valuation (-)',
                      CurrencyService.format(returnedVal),
                      isDark: isDark,
                      color: AppColors.amberOrange,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.white24),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRefundable
                              ? 'STORE OWES CUSTOMER'
                              : 'CUSTOMER PAYS STORE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isRefundable
                                ? AppColors.amberOrange
                                : AppColors.emeraldGreen,
                          ),
                        ),
                        Text(
                          CurrencyService.format(finalDiff),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isRefundable
                                ? AppColors.amberOrange
                                : AppColors.emeraldGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                ),
                onPressed: () {
                  _applyValuation();
                  if (widget.onDismiss != null) widget.onDismiss!();
                },
                child: const Text(
                  'Confirm Valuation',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, {required bool isDark, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
