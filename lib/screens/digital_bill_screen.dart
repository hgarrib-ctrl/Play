import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/billing_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../services/currency_service.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_text_field.dart';
import 'receipt_preview_screen.dart';

class DigitalBillScreen extends StatefulWidget {
  final BillingController? billingController;
  final SettingsController settingsController;
  final Bill? savedBill; // If non-null, view-only mode from History

  const DigitalBillScreen({
    super.key,
    this.billingController,
    required this.settingsController,
    this.savedBill,
  });

  bool get isViewOnly => savedBill != null;

  @override
  State<DigitalBillScreen> createState() => _DigitalBillScreenState();
}

class _DigitalBillScreenState extends State<DigitalBillScreen> {
  String _previewBillNumber = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isViewOnly && widget.billingController != null) {
      widget.billingController!.previewNextBillNumber().then((nextNum) {
        if (mounted) setState(() => _previewBillNumber = nextNum);
      });
    }
  }

  void _showPriceOverrideDialog(int index, BillItem item) {
    if (widget.isViewOnly || widget.billingController == null) return;
    final controller = TextEditingController(text: item.unitPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Edit Unit Price for ${item.productName}',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original Price: ${CurrencyService.format(item.originalPrice)}',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: controller,
                labelText: 'New Unit Price (₹)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
            ],
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
                backgroundColor: AppColors.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
              ),
              onPressed: () {
                final newPrice = double.tryParse(controller.text.trim());
                if (newPrice != null && newPrice >= 0) {
                  widget.billingController!.overrideItemPrice(index, newPrice);
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

  void _showAddAdjustmentDialog({required bool isDiscount}) {
    if (widget.isViewOnly || widget.billingController == null) return;
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
                    widget.billingController!.applyDiscount(val);
                  } else {
                    widget.billingController!.applyAdditionalCharge(val);
                  }
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

  Future<void> _processPaymentAndReturn({required String paymentMethod}) async {
    if (widget.billingController == null) return;
    final controller = widget.billingController!;

    if (controller.items.isEmpty && (!controller.isExchangeMode || controller.returnedItemValue <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot complete an empty bill.'),
          backgroundColor: AppColors.coralRed,
        ),
      );
      return;
    }

    final savedBill = await controller.completeBill(paymentMethod: paymentMethod);
    if (!mounted || savedBill == null) return;

    // Pop back directly to Billing Screen for instant speed response
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: paymentMethod == 'ONLINE' ? const Color(0xFF0F9D58) : AppColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Paid via $paymentMethod: ${CurrencyService.format(savedBill.finalTotal)} • ${savedBill.billNumber} Saved!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'RECEIPT',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptPreviewScreen(
                  bill: savedBill,
                  settings: widget.settingsController.settings,
                ),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showOnlineUpiPaymentModal({required double amount, required String billNo}) {
    final settings = widget.settingsController.settings;
    final upiId = settings.shopUpiId.trim();
    final shopName = settings.shopName.trim().isEmpty ? 'QuickBill Store' : settings.shopName.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Standard NPCI UPI Intent URI for QR scanning
    final upiUri = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shopName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('Bill $billNo')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, color: AppColors.electricBlue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Scan & Pay (Amount Auto-Filled)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Customer scans with GPay / PhonePe / Paytm / BHIM',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 16),

              // Prominent Amount Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emeraldGreen, width: 1),
                ),
                child: Text(
                  CurrencyService.format(amount),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Display
              if (upiId.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: upiUri,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'UPI ID: $upiId',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                  ),
                ),
              ] else if (settings.shopQrPath != null && File(settings.shopQrPath!).existsSync()) ...[
                // Custom Uploaded QR Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(settings.shopQrPath!),
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: Enter UPI ID in Shop Settings for auto-amount prefill',
                  style: TextStyle(fontSize: 11, color: AppColors.amberOrange),
                ),
              ] else ...[
                // Prompt to configure UPI in Settings
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amberOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amberOrange),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.amberOrange, size: 28),
                      const SizedBox(height: 6),
                      const Text(
                        'UPI ID Not Set Yet',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.amberOrange),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add your UPI ID (e.g. yourname@upi) in Shop Settings to generate auto-filling QR codes instantly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Confirm Payment Received Button
              GlassButton(
                text: 'Payment Received (Done)',
                icon: Icons.check_circle_outline,
                variant: GlassButtonVariant.success,
                isExpanded: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  _processPaymentAndReturn(paymentMethod: 'ONLINE');
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel / Change Method', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPdfReceipt(Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(
          bill: bill,
          settings: widget.settingsController.settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = widget.settingsController.settings;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Values either from live controller or saved Bill
    final List<BillItem> items;
    final String billNo;
    final String? customerName;
    final String? customerMobile;
    final double subtotal;
    final double discount;
    final double additionalCharge;
    final double returnedValue;
    final String? returnedNotes;
    final double finalTotal;
    final bool isRefundable;
    final bool isExchange;
    final String paymentMethod;
    final DateTime createdAt;

    if (widget.isViewOnly) {
      final b = widget.savedBill!;
      items = b.items;
      billNo = b.billNumber;
      customerName = b.billName;
      customerMobile = b.customerPhone;
      subtotal = b.subtotal;
      discount = b.discountAmount;
      additionalCharge = b.additionalCharge;
      returnedValue = b.returnedItemValue;
      returnedNotes = b.returnedItemNotes;
      finalTotal = b.finalTotal;
      isRefundable = b.isRefundable;
      isExchange = b.isExchange;
      paymentMethod = b.paymentMethod;
      createdAt = b.createdAt;
    } else {
      final c = widget.billingController!;
      items = c.items;
      billNo = _previewBillNumber.isNotEmpty ? _previewBillNumber : 'QB-PREVIEW';
      customerName = c.billName;
      customerMobile = c.customerPhone;
      subtotal = c.subtotal;
      discount = c.discountAmount;
      additionalCharge = c.additionalCharge;
      returnedValue = c.returnedItemValue;
      returnedNotes = c.returnedItemNotes;
      finalTotal = c.finalTotal;
      isRefundable = c.isRefundable;
      isExchange = c.isExchangeMode;
      paymentMethod = c.paymentMethod;
      createdAt = DateTime.now();
    }

    // Build a temporary snapshot for PDF preview if requested in active mode
    final currentBillSnapshot = widget.isViewOnly
        ? widget.savedBill!
        : Bill(
            billNumber: billNo,
            billName: customerName,
            customerPhone: customerMobile,
            billType: isExchange ? BillType.exchange : BillType.regular,
            subtotal: subtotal,
            discountAmount: discount,
            additionalCharge: additionalCharge,
            returnedItemValue: returnedValue,
            returnedItemNotes: returnedNotes,
            finalTotal: finalTotal,
            isRefundable: isRefundable,
            paymentMethod: paymentMethod,
            items: List<BillItem>.from(items),
          );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.isViewOnly ? 'Invoice $billNo' : 'Digital Bill ($billNo)',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Optional PDF Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.softCyan),
            tooltip: 'Share / Print PDF',
            onPressed: () => _openPdfReceipt(currentBillSnapshot),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Shop & Invoice Header Glass Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                      borderRadius: AppStyles.borderRadiusMedium,
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                settings.shopName.isEmpty ? 'QuickBill Store' : settings.shopName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isExchange
                                    ? AppColors.amberOrange.withValues(alpha: 0.2)
                                    : AppColors.electricBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isExchange ? 'EXCHANGE' : 'INVOICE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isExchange ? AppColors.amberOrange : AppColors.electricBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (settings.shopAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            settings.shopAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                        if (settings.shopPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ph: ${settings.shopPhone}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                        const Divider(height: 16, thickness: 0.8),

                        // Date, Customer & Phone Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormat.format(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                            if (widget.isViewOnly)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: paymentMethod == 'ONLINE'
                                      ? AppColors.emeraldGreen.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  paymentMethod,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: paymentMethod == 'ONLINE'
                                        ? AppColors.emeraldGreen
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (customerName != null && customerName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.softCyan),
                              const SizedBox(width: 4),
                              Text(
                                'Customer: $customerName',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.softCyan),
                              ),
                            ],
                          ),
                        ],
                        if (customerMobile != null && customerMobile.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone_android, size: 14, color: AppColors.textSecondaryDark),
                              const SizedBox(width: 4),
                              Text(
                                'Mobile: $customerMobile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Section Title: Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items in Bill (${items.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      if (!widget.isViewOnly)
                        const Text(
                          'Tap item to edit price',
                          style: TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                      borderRadius: AppStyles.borderRadiusMedium,
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      ),
                    ),
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No items in this bill',
                                style: TextStyle(color: AppColors.textMutedDark),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                onTap: () => _showPriceOverrideDialog(index, item),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                    if (item.hasPriceOverride)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        margin: const EdgeInsets.only(left: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.softCyan.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Custom',
                                          style: TextStyle(fontSize: 9, color: AppColors.softCyan, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${CurrencyService.format(item.unitPrice)} × ${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      CurrencyService.format(item.itemTotal),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    if (!widget.isViewOnly) ...[
                                      const SizedBox(width: 8),
                                      // Quick decrement
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            widget.billingController!.decrementQuantity(index);
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.remove, size: 16, color: Colors.white70),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Quick increment
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            widget.billingController!.incrementQuantity(index);
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(15),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.electricBlue.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.add, size: 16, color: AppColors.electricBlue),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 14),

                  // Bill Adjustments (Discount / Charges Buttons) in active mode
                  if (!widget.isViewOnly) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emeraldGreen,
                              side: const BorderSide(color: AppColors.emeraldGreen, width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                            ),
                            icon: const Icon(Icons.local_offer_outlined, size: 16),
                            label: Text(discount > 0 ? 'Disc: ₹${discount.toStringAsFixed(0)}' : 'Add Discount'),
                            onPressed: () => _showAddAdjustmentDialog(isDiscount: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.electricBlue,
                              side: const BorderSide(color: AppColors.electricBlue, width: 0.8),
                              shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: Text(additionalCharge > 0 ? 'Chg: ₹${additionalCharge.toStringAsFixed(0)}' : 'Add Charge'),
                            onPressed: () => _showAddAdjustmentDialog(isDiscount: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Calculations Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                      borderRadius: AppStyles.borderRadiusMedium,
                      border: Border.all(
                        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Subtotal', CurrencyService.format(subtotal), isDark),
                        if (discount > 0)
                          _summaryRow(
                            'Discount (-)',
                            CurrencyService.format(discount),
                            isDark,
                            valueColor: AppColors.emeraldGreen,
                          ),
                        if (additionalCharge > 0)
                          _summaryRow(
                            'Additional Charges (+)',
                            CurrencyService.format(additionalCharge),
                            isDark,
                          ),
                        if (isExchange && returnedValue > 0) ...[
                          const Divider(height: 12),
                          _summaryRow('New Purchases', CurrencyService.format(subtotal), isDark),
                          _summaryRow(
                            'Returned Item Value (-)',
                            CurrencyService.format(returnedValue),
                            isDark,
                            valueColor: AppColors.amberOrange,
                          ),
                          if (returnedNotes != null && returnedNotes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Note: $returnedNotes',
                                style: const TextStyle(fontSize: 11, color: AppColors.amberOrange),
                              ),
                            ),
                        ],
                        const Divider(height: 16, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isRefundable ? 'AMOUNT OWED TO CUSTOMER' : 'FINAL PAYABLE AMOUNT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isRefundable ? AppColors.amberOrange : (isDark ? Colors.white : AppColors.textPrimaryLight),
                              ),
                            ),
                            Text(
                              CurrencyService.format(finalTotal),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isRefundable
                                    ? AppColors.amberOrange
                                    : (isDark ? AppColors.emeraldGreen : const Color(0xFF0F9D58)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // BOTTOM PAYMENT BAR (Active mode) or RE-ORDER BAR (History mode)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                ),
              ),
            ),
            child: widget.isViewOnly
                ? Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          text: 'View / Share PDF',
                          icon: Icons.picture_as_pdf,
                          variant: GlassButtonVariant.primary,
                          onPressed: () => _openPdfReceipt(currentBillSnapshot),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Pay Cash Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
                          label: const Text(
                            'Pay Cash',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          onPressed: () => _processPaymentAndReturn(paymentMethod: 'CASH'),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Pay Online (UPI QR) Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                          label: const Text(
                            'Pay Online (QR)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          onPressed: () => _showOnlineUpiPaymentModal(
                            amount: finalTotal,
                            billNo: billNo,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
