import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> exportBackupJson() async {
    final db = await _dbHelper.database;
    final products = await db.query('products');
    final categories = await db.query('categories');
    final bills = await db.query('bills');
    final billItems = await db.query('bill_items');

    final backupData = {
      'app': 'QuickBill',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories,
      'products': products,
      'bills': bills,
      'bill_items': billItems,
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<bool> restoreFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data['app'] != 'QuickBill') {
        throw Exception('Invalid QuickBill backup file format');
      }

      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Clear existing
        await txn.delete('bill_items');
        await txn.delete('bills');
        await txn.delete('products');
        await txn.delete('categories');

        // Restore categories
        if (data['categories'] is List) {
          for (final c in data['categories']) {
            await txn.insert('categories', Map<String, dynamic>.from(c as Map));
          }
        }

        // Restore products
        if (data['products'] is List) {
          for (final p in data['products']) {
            await txn.insert('products', Map<String, dynamic>.from(p as Map));
          }
        }

        // Restore bills
        if (data['bills'] is List) {
          for (final b in data['bills']) {
            await txn.insert('bills', Map<String, dynamic>.from(b as Map));
          }
        }

        // Restore bill items
        if (data['bill_items'] is List) {
          for (final bi in data['bill_items']) {
            await txn.insert('bill_items', Map<String, dynamic>.from(bi as Map));
          }
        }
      });

      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return false;
    }
  }

  Future<bool> clearAllData() async {
    try {
      final db = await _dbHelper.database;
      await db.transaction((txn) async {
        await txn.delete('bill_items');
        await txn.delete('bills');
        await txn.delete('products');
        await txn.delete('categories');
      });
      return true;
    } catch (e) {
      debugPrint('Error clearing data: $e');
      return false;
    }
  }
}
