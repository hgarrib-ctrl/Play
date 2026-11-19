import 'package:sqflite/sqflite.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import 'database_helper.dart';

class BillDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> saveBill(Bill bill, List<BillItem> items) async {
    return await _dbHelper.insertBillWithItems(bill, items);
  }

  Future<List<Bill>> getAllBills({
    String? query,
    BillType? billType,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic> args = [];

    if (query != null && query.trim().isNotEmpty) {
      where = '(bill_number LIKE ? OR bill_name LIKE ?)';
      final p = '%${query.trim()}%';
      args.addAll([p, p]);
    }

    if (billType != null) {
      final typeStr = billType == BillType.exchange ? 'EXCHANGE' : 'REGULAR';
      if (where != null) {
        where += ' AND bill_type = ?';
      } else {
        where = 'bill_type = ?';
      }
      args.add(typeStr);
    }

    final billMaps = await db.query(
      'bills',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    List<Bill> bills = [];
    for (final bMap in billMaps) {
      final billId = bMap['id'] as int;
      final itemMaps = await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: [billId],
      );
      final items = itemMaps.map((im) => BillItem.fromMap(im)).toList();
      bills.add(Bill.fromMap(bMap, items: items));
    }
    return bills;
  }

  Future<Bill?> getBillById(int billId) async {
    final db = await _dbHelper.database;
    final billMaps = await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
      limit: 1,
    );
    if (billMaps.isEmpty) return null;

    final itemMaps = await db.query(
      'bill_items',
      where: 'bill_id = ?',
      whereArgs: [billId],
    );
    final items = itemMaps.map((im) => BillItem.fromMap(im)).toList();
    return Bill.fromMap(billMaps.first, items: items);
  }

  Future<int> updateBillName(int billId, String? newName) async {
    final db = await _dbHelper.database;
    return await db.update(
      'bills',
      {'bill_name': newName?.trim().isEmpty == true ? null : newName?.trim()},
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  Future<int> deleteBill(int billId) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
      return await txn.delete('bills', where: 'id = ?', whereArgs: [billId]);
    });
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final todayResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_bills,
        COALESCE(SUM(CASE WHEN is_refundable = 0 THEN final_total ELSE -final_total END), 0.0) as net_sales,
        COALESCE(SUM(CASE WHEN bill_type = 'EXCHANGE' THEN 1 ELSE 0 END), 0) as exchange_count
      FROM bills
      WHERE created_at >= ?
    ''', [startOfDay]);

    final allTimeResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as all_bills,
        COALESCE(SUM(CASE WHEN is_refundable = 0 THEN final_total ELSE -final_total END), 0.0) as all_sales
      FROM bills
    ''');

    return {
      'todayBills': Sqflite.firstIntValue(todayResult) ?? 0,
      'todaySales': (todayResult.first['net_sales'] as num?)?.toDouble() ?? 0.0,
      'todayExchanges': (todayResult.first['exchange_count'] as num?)?.toInt() ?? 0,
      'allTimeBills': (allTimeResult.first['all_bills'] as num?)?.toInt() ?? 0,
      'allTimeSales': (allTimeResult.first['all_sales'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<String>> getTopDemandedProductNames({int limit = 12}) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT product_name, SUM(quantity) as total_qty
      FROM bill_items
      GROUP BY product_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [limit]);
    return results.map((r) => r['product_name'] as String).toList();
  }

  Future<String> generateNextBillNumber() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final datePrefix = 'QB-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery(
      "SELECT bill_number FROM bills WHERE bill_number LIKE ? ORDER BY id DESC LIMIT 1",
      ['$datePrefix%'],
    );

    if (result.isEmpty) {
      return '$datePrefix-001';
    } else {
      final lastNumStr = result.first['bill_number'] as String;
      final parts = lastNumStr.split('-');
      if (parts.length >= 3) {
        final seq = int.tryParse(parts.last) ?? 0;
        return '$datePrefix-${(seq + 1).toString().padLeft(3, '0')}';
      }
      return '$datePrefix-001';
    }
  }
}
