import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class DatabaseHelper {
  static const String dbName = 'quickbill_v1.db';
  static const int dbVersion = 2;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI for desktop/tests if not on mobile
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      path = join(docsDir.path, dbName);
    } catch (_) {
      final defaultDatabasesPath = await getDatabasesPath();
      path = join(defaultDatabasesPath, dbName);
    }

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE bills ADD COLUMN customer_phone TEXT');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        icon_name TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT DEFAULT 'Other',
        image_path TEXT,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Index for fast search
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_active ON products(is_active)');

    // Bills table
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_number TEXT UNIQUE NOT NULL,
        bill_name TEXT,
        customer_phone TEXT,
        bill_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0.0,
        additional_charge REAL DEFAULT 0.0,
        returned_item_value REAL DEFAULT 0.0,
        returned_item_notes TEXT,
        final_total REAL NOT NULL,
        is_refundable INTEGER DEFAULT 0,
        payment_method TEXT DEFAULT 'CASH',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_bills_created ON bills(created_at DESC)');
    await db.execute('CREATE INDEX idx_bills_name ON bills(bill_name)');

    // Bill Items table (independent snapshot: unit_price, product_name preserved even if product is deleted)
    await db.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        original_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        item_total REAL NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_bill_items_bill_id ON bill_items(bill_id)');

    // Seed default categories
    final now = DateTime.now().millisecondsSinceEpoch;
    final initialCategories = [
      'Kitchen',
      'Electronics',
      'Accessories',
      'Clothing',
      'Groceries',
      'Festive',
      'Other',
    ];
    for (final cat in initialCategories) {
      await db.insert('categories', {
        'name': cat,
        'created_at': now,
      });
    }

    // Seed realistic retail products for instant out-of-the-box billing speed test
    final seedProducts = [
      {'name': 'Steel Plate (Dinner)', 'price': 250.0, 'category': 'Kitchen'},
      {'name': 'Steel Bowl (Katori)', 'price': 150.0, 'category': 'Kitchen'},
      {'name': 'Stainless Steel Jug (2L)', 'price': 450.0, 'category': 'Kitchen'},
      {'name': 'Non-stick Fry Pan (24cm)', 'price': 899.0, 'category': 'Kitchen'},
      {'name': 'Brass Pooja Thali Set', 'price': 1250.0, 'category': 'Festive'},
      {'name': 'Brass Diya (Set of 2)', 'price': 350.0, 'category': 'Festive'},
      {'name': 'Silver Laxmi-Ganesh Coin', 'price': 1500.0, 'category': 'Festive'},
      {'name': 'Copper Water Bottle (1L)', 'price': 750.0, 'category': 'Accessories'},
      {'name': 'Smart LED Bulb (12W)', 'price': 420.0, 'category': 'Electronics'},
      {'name': 'Extension Cord 4-Socket', 'price': 380.0, 'category': 'Electronics'},
      {'name': 'USB-C Fast Charging Cable', 'price': 250.0, 'category': 'Accessories'},
      {'name': 'Digital Table Clock', 'price': 550.0, 'category': 'Electronics'},
    ];

    for (final p in seedProducts) {
      await db.insert('products', {
        'name': p['name'],
        'price': p['price'],
        'category': p['category'],
        'image_path': null,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // Transactional Bill Saving
  Future<int> insertBillWithItems(Bill bill, List<BillItem> items) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      final billMap = bill.toMap();
      billMap.remove('id');
      final billId = await txn.insert('bills', billMap);

      for (final item in items) {
        final itemMap = item.toMap();
        itemMap.remove('id');
        itemMap['bill_id'] = billId;
        await txn.insert('bill_items', itemMap);
      }
      return billId;
    });
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
