import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quickbill/controllers/billing_controller.dart';
import 'package:quickbill/controllers/calculator_controller.dart';
import 'package:quickbill/models/bill.dart';
import 'package:quickbill/models/bill_item.dart';
import 'package:quickbill/models/product.dart';
import 'package:quickbill/models/shop_settings.dart';
import 'package:quickbill/services/currency_service.dart';
import 'package:quickbill/services/receipt_service.dart';
import 'package:quickbill/services/backup_service.dart';
import 'package:quickbill/database/database_helper.dart';
import 'package:quickbill/database/product_dao.dart';
import 'package:quickbill/database/bill_dao.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  group('Scenario 10: Independent Calculator (Mode A)', () {
    late CalculatorController calc;

    setUp(() {
      calc = CalculatorController();
      calc.setMode(CalculatorMode.independent);
    });

    test('Addition: 500 + 250 = 750', () {
      calc.input('500');
      calc.input('+');
      calc.input('250');
      calc.calculate();
      expect(calc.result, '750');
      expect(calc.numericResult, 750.0);
    });

    test('Multiplication with Decimals: 12.5 × 4 = 50', () {
      calc.input('12.5');
      calc.input('×');
      calc.input('4');
      calc.calculate();
      expect(calc.result, '50');
      expect(calc.numericResult, 50.0);
    });

    test('Division and precedence: 100 + 50 ÷ 2 = 125', () {
      calc.input('100');
      calc.input('+');
      calc.input('50');
      calc.input('÷');
      calc.input('2');
      calc.calculate();
      expect(calc.result, '125');
      expect(calc.numericResult, 125.0);
    });

    test('Division by zero safe handling', () {
      calc.input('100');
      calc.input('÷');
      calc.input('0');
      calc.calculate();
      expect(calc.result, 'Error');
    });

    test('Clear and Backspace functionality', () {
      calc.input('450');
      calc.backspace();
      expect(calc.expression, '45');
      calc.clear();
      expect(calc.expression, '0');
      expect(calc.result, '0');
    });
  });

  group('Indian Currency Formatting', () {
    test('Standard and large Indian currency values', () {
      expect(CurrencyService.format(250, symbol: '₹'), '₹ 250.00');
      expect(CurrencyService.format(125500, symbol: '₹'), '₹ 1,25,500.00');
      expect(CurrencyService.format(1000000, symbol: '₹'), '₹ 10,00,000.00');
      expect(CurrencyService.format(250, symbol: '₹', showDecimals: false), '₹ 250');
    });

    test('Compact format for chips', () {
      expect(CurrencyService.formatCompact(500), '₹500');
      expect(CurrencyService.formatCompact(4500), '₹4.5k');
      expect(CurrencyService.formatCompact(150000), '₹1.5L');
    });
  });

  group('Scenarios 3-9, 11-12: Billing Engine & Calculations', () {
    late BillingController billing;
    final plate = Product(id: 1, name: 'Steel Plate', price: 250.0, category: 'Kitchen');
    final bowl = Product(id: 2, name: 'Steel Bowl', price: 150.0, category: 'Kitchen');

    setUp(() {
      billing = BillingController();
    });

    test('Scenario 3: Add multiple products to bill', () {
      billing.addProduct(plate);
      billing.addProduct(bowl);
      expect(billing.items.length, 2);
      expect(billing.itemCount, 2);
      expect(billing.subtotal, 400.0);
      expect(billing.finalTotal, 400.0);
    });

    test('Scenario 4: Add same product repeatedly increments quantity', () {
      billing.addProduct(plate);
      billing.addProduct(plate);
      expect(billing.items.length, 1);
      expect(billing.items[0].quantity, 2);
      expect(billing.items[0].itemTotal, 500.0);
      expect(billing.subtotal, 500.0);
    });

    test('Scenario 5: Increase and decrease quantities', () {
      billing.addProduct(plate);
      billing.incrementQuantity(0);
      expect(billing.items[0].quantity, 2);
      expect(billing.subtotal, 500.0);

      billing.decrementQuantity(0);
      expect(billing.items[0].quantity, 1);
      expect(billing.subtotal, 250.0);

      billing.decrementQuantity(0); // quantity becomes 0 -> removed
      expect(billing.items.isEmpty, true);
      expect(billing.subtotal, 0.0);
    });

    test('Scenario 6: Remove product directly', () {
      billing.addProduct(plate);
      billing.addProduct(bowl);
      billing.removeItem(0);
      expect(billing.items.length, 1);
      expect(billing.items[0].productName, 'Steel Bowl');
    });

    test('Scenario 7: Override item price on current bill without changing product catalog price', () {
      billing.addProduct(plate);
      expect(billing.items[0].unitPrice, 250.0);
      expect(plate.price, 250.0);

      billing.overrideItemPrice(0, 220.0);
      expect(billing.items[0].unitPrice, 220.0);
      expect(billing.items[0].hasPriceOverride, true);
      expect(billing.subtotal, 220.0);
      expect(plate.price, 250.0); // original preserved
    });

    test('Scenario 8: Apply discount', () {
      billing.addProduct(plate); // 250
      billing.addProduct(plate); // 250 -> 500
      billing.applyDiscount(50.0);
      expect(billing.discountAmount, 50.0);
      expect(billing.finalTotal, 450.0);
    });

    test('Scenario 9: Add additional charge', () {
      billing.addProduct(plate); // 250
      billing.applyAdditionalCharge(30.0); // packing/delivery
      expect(billing.additionalCharge, 30.0);
      expect(billing.finalTotal, 280.0);
    });

    test('Scenario 11: Apply calculator results as adjustment', () {
      billing.addProduct(plate); // 250
      final calc = CalculatorController();
      calc.input('40');
      calc.input('+');
      calc.input('10');
      calc.calculate();
      expect(calc.numericResult, 50.0);

      billing.applyDiscount(calc.numericResult);
      expect(billing.finalTotal, 200.0);
    });

    test('Scenario 12: Undo adjustments and actions', () {
      billing.addProduct(plate); // 250
      expect(billing.subtotal, 250.0);

      billing.applyDiscount(50.0);
      expect(billing.finalTotal, 200.0);
      expect(billing.canUndo, true);

      billing.undo(); // Undoes discount
      expect(billing.discountAmount, 0.0);
      expect(billing.finalTotal, 250.0);

      billing.undo(); // Undoes adding plate
      expect(billing.items.isEmpty, true);
    });
  });

  group('Scenarios 14-16: Exchange Mode', () {
    late BillingController billing;
    final dinnerSet = Product(id: 10, name: 'Dinner Set', price: 2000.0, category: 'Kitchen');
    final smallThali = Product(id: 11, name: 'Small Thali', price: 1000.0, category: 'Kitchen');

    setUp(() {
      billing = BillingController();
      billing.toggleExchangeMode(true);
    });

    test('Scenario 15: Exchange where customer pays extra (New: 2000, Returned: 700 -> Pays 1300)', () {
      billing.addProduct(dinnerSet); // 2000
      billing.setReturnedItemDetails(value: 700.0, notes: 'Old Aluminium Cooker');

      expect(billing.subtotal, 2000.0);
      expect(billing.returnedItemValue, 700.0);
      expect(billing.isRefundable, false); // Customer pays
      expect(billing.finalTotal, 1300.0);
    });

    test('Scenario 16: Exchange where store owes customer (New: 1000, Returned: 1500 -> Owed 500)', () {
      billing.addProduct(smallThali); // 1000
      billing.setReturnedItemDetails(value: 1500.0, notes: 'Old Silver Pooja Plate');

      expect(billing.subtotal, 1000.0);
      expect(billing.returnedItemValue, 1500.0);
      expect(billing.isRefundable, true); // Store owes customer
      expect(billing.finalTotal, 500.0);
    });
  });

  group('Scenarios 1, 2, 13, 17, 20: SQLite Persistence & DAO', () {
    late ProductDao productDao;
    late BillDao billDao;

    setUp(() {
      productDao = ProductDao();
      billDao = BillDao();
    });

    test('Scenario 1 & 2: Add product, query, verify persistence', () async {
      final p = Product(
        name: 'Festive Silver Coin 10g',
        price: 950.0,
        category: 'Festive',
      );
      final id = await productDao.insertProduct(p);
      expect(id, greaterThan(0));

      final retrieved = await productDao.getProductById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Festive Silver Coin 10g');
      expect(retrieved.price, 950.0);
      expect(retrieved.category, 'Festive');
    });

    test('Scenario 13: Create a bill without a name (Speed Skip)', () async {
      final billNo = await billDao.generateNextBillNumber();
      final bill = Bill(
        billNumber: billNo,
        billName: null, // SKIPPED
        billType: BillType.regular,
        subtotal: 500.0,
        finalTotal: 500.0,
      );
      final items = [
        BillItem(productName: 'Steel Plate', unitPrice: 250.0, quantity: 2),
      ];

      final billId = await billDao.saveBill(bill, items);
      expect(billId, greaterThan(0));

      final saved = await billDao.getBillById(billId);
      expect(saved, isNotNull);
      expect(saved!.billName, isNull);
      expect(saved.finalTotal, 500.0);
      expect(saved.items.length, 1);
    });

    test('Scenario 14 & 17: Save named exchange bill and reopen/reuse as new bill', () async {
      final billNo = await billDao.generateNextBillNumber();
      final bill = Bill(
        billNumber: billNo,
        billName: 'Exchange Rahul',
        billType: BillType.exchange,
        subtotal: 2000.0,
        returnedItemValue: 700.0,
        returnedItemNotes: 'Old Mixer',
        finalTotal: 1300.0,
        isRefundable: false,
      );
      final items = [
        BillItem(productName: 'Dinner Set', unitPrice: 2000.0, quantity: 1),
      ];

      final billId = await billDao.saveBill(bill, items);
      final saved = await billDao.getBillById(billId);
      expect(saved!.billName, 'Exchange Rahul');
      expect(saved.isExchange, true);

      // Reopen in billing controller
      final billing = BillingController();
      billing.loadFromPreviousBill(saved);
      expect(billing.items.length, 1);
      expect(billing.isExchangeMode, true);
      expect(billing.returnedItemValue, 700.0);
      expect(billing.finalTotal, 1300.0);
    });
  });

  group('Scenario 18: Receipt PDF Document Generation', () {
    test('Generate valid PDF document for regular bill', () async {
      final bill = Bill(
        billNumber: 'QB-20261105-001',
        billName: 'Diwali Special',
        billType: BillType.regular,
        subtotal: 1000.0,
        discountAmount: 100.0,
        finalTotal: 900.0,
        items: [
          BillItem(productName: 'Brass Pooja Thali', unitPrice: 500.0, quantity: 2),
        ],
      );
      final settings = ShopSettings(
        shopName: 'Shree Ganesh Mart',
        shopAddress: 'Main Market, City Center',
        shopPhone: '9876543210',
      );

      final pdfDoc = await ReceiptService.generatePdf(bill: bill, settings: settings);
      final bytes = await pdfDoc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000)); // Non-empty valid PDF bytes
    });

    test('Generate valid PDF document for exchange bill', () async {
      final bill = Bill(
        billNumber: 'QB-20261105-002',
        billName: 'Exchange Customer',
        billType: BillType.exchange,
        subtotal: 2000.0,
        returnedItemValue: 2500.0,
        returnedItemNotes: 'Damaged item return',
        finalTotal: 500.0,
        isRefundable: true,
        items: [
          BillItem(productName: 'Steel Cookware', unitPrice: 2000.0, quantity: 1),
        ],
      );
      final settings = ShopSettings();
      final pdfDoc = await ReceiptService.generatePdf(bill: bill, settings: settings);
      final bytes = await pdfDoc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('Backup and Restore (JSON)', () {
    test('Export and restore JSON without loss', () async {
      final backupService = BackupService();
      final jsonStr = await backupService.exportBackupJson();
      expect(jsonStr, contains('"app": "QuickBill"'));
      expect(jsonStr, contains('"products"'));
      expect(jsonStr, contains('"categories"'));
      expect(jsonStr, contains('"bills"'));

      final restored = await backupService.restoreFromJson(jsonStr);
      expect(restored, true);
    });
  });
}
