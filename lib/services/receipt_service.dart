import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';
import '../models/shop_settings.dart';
import 'currency_service.dart';

class ReceiptService {
  static Future<pw.Document> generatePdf({
    required Bill bill,
    required ShopSettings settings,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.shopName.isEmpty ? 'QuickBill Store' : settings.shopName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        if (settings.shopAddress.isNotEmpty) ...[
                          pw.Text(
                            'Address: ${settings.shopAddress}',
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 2),
                        ],
                        if (settings.shopPhone.isNotEmpty) ...[
                          pw.Text(
                            'Contact / Tel: ${settings.shopPhone}',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 2),
                        ],
                        if (settings.shopGstin.isNotEmpty) ...[
                          pw.Text(
                            'GSTIN: ${settings.shopGstin}',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
                          ),
                          pw.SizedBox(height: 2),
                        ],
                        if (settings.shopUpiId.isNotEmpty) ...[
                          pw.Text(
                            'UPI ID: ${settings.shopUpiId}',
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: bill.isExchange ? PdfColors.amber100 : PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(
                            color: bill.isExchange ? PdfColors.amber700 : PdfColors.blue700,
                            width: 0.8,
                          ),
                        ),
                        child: pw.Text(
                          bill.isExchange ? 'EXCHANGE BILL' : 'RETAIL INVOICE',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: bill.isExchange ? PdfColors.amber900 : PdfColors.blue900,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Invoice #: ${bill.billNumber}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Date: $formattedDate',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      if (bill.billName != null && bill.billName!.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Customer: ${bill.billName}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      ],
                      if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Mobile: ${bill.customerPhone}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 3),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: bill.paymentMethod == 'ONLINE' ? PdfColors.green50 : PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(
                            color: bill.paymentMethod == 'ONLINE' ? PdfColors.green600 : PdfColors.grey400,
                            width: 0.5,
                          ),
                        ),
                        child: pw.Text(
                          'PAID VIA ${bill.paymentMethod}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: bill.paymentMethod == 'ONLINE' ? PdfColors.green900 : PdfColors.grey800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 10),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // S.No
                  1: const pw.FlexColumnWidth(4.0), // Product Name
                  2: const pw.FlexColumnWidth(1.6), // Unit Price
                  3: const pw.FlexColumnWidth(1.2), // Qty
                  4: const pw.FlexColumnWidth(1.8), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _tableHeaderCell('#'),
                      _tableHeaderCell('Item Description'),
                      _tableHeaderCell('Rate (INR)', align: pw.TextAlign.right),
                      _tableHeaderCell('Qty', align: pw.TextAlign.center),
                      _tableHeaderCell('Total (INR)', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(bill.items.length, (index) {
                    final item = bill.items[index];
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                      ),
                      children: [
                        _tableBodyCell('${index + 1}', align: pw.TextAlign.center),
                        _tableBodyCell(
                          item.hasPriceOverride
                              ? '${item.productName} *'
                              : item.productName,
                        ),
                        _tableBodyCell(
                          CurrencyService.format(item.unitPrice, symbol: ''),
                          align: pw.TextAlign.right,
                        ),
                        _tableBodyCell('${item.quantity}', align: pw.TextAlign.center),
                        _tableBodyCell(
                          CurrencyService.format(item.itemTotal, symbol: ''),
                          align: pw.TextAlign.right,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              if (bill.items.any((i) => i.hasPriceOverride)) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  '* Note: Custom price applied on bill',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                ),
              ],

              pw.SizedBox(height: 16),

              // Summary Calculations
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRow('Subtotal', CurrencyService.format(bill.subtotal, symbol: 'INR')),
                        if (bill.discountAmount > 0)
                          _summaryRow(
                            'Discount (-)',
                            CurrencyService.format(bill.discountAmount, symbol: 'INR'),
                            valueColor: PdfColors.green800,
                          ),
                        if (bill.additionalCharge > 0)
                          _summaryRow(
                            'Charges (+)',
                            CurrencyService.format(bill.additionalCharge, symbol: 'INR'),
                          ),
                        if (bill.isExchange && bill.returnedItemValue > 0) ...[
                          pw.Divider(color: PdfColors.grey300),
                          _summaryRow(
                            'New Purchases',
                            CurrencyService.format(bill.subtotal, symbol: 'INR'),
                          ),
                          _summaryRow(
                            'Returned Item Value',
                            CurrencyService.format(bill.returnedItemValue, symbol: 'INR'),
                            valueColor: PdfColors.amber900,
                          ),
                        ],
                        pw.Divider(color: PdfColors.grey400, thickness: 1),
                        _summaryRow(
                          bill.isRefundable ? 'AMOUNT OWED TO CUSTOMER' : 'FINAL PAYABLE AMOUNT',
                          CurrencyService.format(bill.finalTotal, symbol: 'INR'),
                          isBold: true,
                          fontSize: 12,
                          valueColor: bill.isRefundable ? PdfColors.amber900 : PdfColors.blue900,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (bill.isExchange && bill.returnedItemNotes != null && bill.returnedItemNotes!.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.TableBorder.all(color: PdfColors.amber300, width: 0.5),
                  ),
                  child: pw.Text(
                    'Exchange Item Details: ${bill.returnedItemNotes}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.amber900),
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer Note
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      settings.receiptFooter.isEmpty
                          ? 'Thank you for your visit!'
                          : settings.receiptFooter,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated quickly with QuickBill App',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
      ),
    );
  }

  static pw.Widget _tableBodyCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor ?? (isBold ? PdfColors.black : PdfColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printReceipt({
    required Bill bill,
    required ShopSettings settings,
  }) async {
    final pdf = await generatePdf(bill: bill, settings: settings);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${bill.billNumber}.pdf',
    );
  }

  static Future<void> shareReceipt({
    required Bill bill,
    required ShopSettings settings,
  }) async {
    final pdf = await generatePdf(bill: bill, settings: settings);
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: '${bill.billNumber}.pdf');
  }
}
