import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<String>> getAllCategoryNames() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'categories',
      columns: ['name'],
      orderBy: 'id ASC',
    );
    final list = maps.map((m) => m['name'] as String).toList();
    if (!list.contains('All')) {
      list.insert(0, 'All');
    }
    return list;
  }

  Future<int> insertCategory(String name) async {
    final db = await _dbHelper.database;
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 0;
    try {
      return await db.insert('categories', {
        'name': cleanName,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      return 0; // Already exists or duplicate
    }
  }

  Future<int> deleteCategory(String name) async {
    if (name == 'All' || name == 'Other') return 0;
    final db = await _dbHelper.database;
    return await db.delete(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
  }
}
