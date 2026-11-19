import 'package:flutter_test/flutter_test.dart';
import 'package:quickbill/controllers/billing_controller.dart';
import 'package:quickbill/controllers/calculator_controller.dart';
import 'package:quickbill/controllers/history_controller.dart';
import 'package:quickbill/controllers/product_controller.dart';
import 'package:quickbill/controllers/settings_controller.dart';
import 'package:quickbill/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('QuickBillApp smoke test - launches directly into billing interface', (WidgetTester tester) async {
    final settingsController = SettingsController();
    final productController = ProductController();
    final billingController = BillingController();
    final calcController = CalculatorController();
    final historyController = HistoryController();

    await tester.pumpWidget(
      QuickBillApp(
        settingsController: settingsController,
        productController: productController,
        billingController: billingController,
        calcController: calcController,
        historyController: historyController,
      ),
    );

    // Verify QuickBill branding and tabs
    expect(find.text('QuickBill'), findsOneWidget);
    expect(find.text('BILL'), findsOneWidget);
    expect(find.text('PRODUCTS'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
