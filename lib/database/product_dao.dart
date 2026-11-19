import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import 'database_helper.dart';

class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Product>> getAllProducts({bool onlyActive = true}) async {
    final db = await _dbHelper.database;
    final whereClause = onlyActive ? 'is_active = 1' : null;
    final maps = await db.query(
      'products',
      where: whereClause,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> searchProducts(String query, {String? category}) async {
    final db = await _dbHelper.database;
    String where = 'is_active = 1';
    List<dynamic> args = [];

    if (query.trim().isNotEmpty) {
      where += ' AND (name LIKE ? OR category LIKE ?)';
      final pattern = '%${query.trim()}%';
      args.addAll([pattern, pattern]);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      where += ' AND category = ?';
      args.add(category);
    }

    final maps = await db.query(
      'products',
      where: where,
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    final map = product.toMap();
    map.remove('id');
    return await db.insert('products', map);
  }

  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    if (product.id == null) return 0;
    final map = product.toMap();
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> softDeleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'is_active': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getProductCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE is_active = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
