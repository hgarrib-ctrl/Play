import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../constants/app_colors.dart';
import '../models/bill.dart';
import '../models/shop_settings.dart';
import '../services/receipt_service.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final Bill bill;
  final ShopSettings? settings;

  const ReceiptPreviewScreen({
    super.key,
    required this.bill,
    this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSettings = settings ?? ShopSettings();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Receipt — ${bill.billNumber}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.softCyan),
            tooltip: 'Share PDF',
            onPressed: () => ReceiptService.shareReceipt(
              bill: bill,
              settings: effectiveSettings,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.electricBlue),
            tooltip: 'Print',
            onPressed: () => ReceiptService.printReceipt(
              bill: bill,
              settings: effectiveSettings,
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final doc = await ReceiptService.generatePdf(
            bill: bill,
            settings: effectiveSettings,
          );
          return doc.save();
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: '${bill.billNumber}.pdf',
      ),
    );
  }
}
