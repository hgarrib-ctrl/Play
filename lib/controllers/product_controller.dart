import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../database/product_dao.dart';
import '../database/category_dao.dart';

class ProductController extends ChangeNotifier {
  final ProductDao _productDao = ProductDao();
  final CategoryDao _categoryDao = CategoryDao();

  List<Product> _products = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  List<Product> get products => _filteredProducts();
  List<Product> get allProducts => _products;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await loadCategories();
    await loadProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final cats = await _categoryDao.getAllCategoryNames();
    _categories = cats;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _products = await _productDao.getAllProducts(onlyActive: true);
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Product> _filteredProducts() {
    return _products.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final queryLower = _searchQuery.trim().toLowerCase();
      final nameMatches = p.name.toLowerCase().contains(queryLower);
      final catMatches = p.category.toLowerCase().contains(queryLower);
      return nameMatches || catMatches;
    }).toList();
  }

  Future<bool> addProduct({
    required String name,
    required double price,
    String category = 'Other',
    String? imagePath,
  }) async {
    final product = Product(
      name: name.trim(),
      price: price,
      category: category.trim().isEmpty ? 'Other' : category.trim(),
      imagePath: imagePath,
    );
    final id = await _productDao.insertProduct(product);
    if (id > 0) {
      await loadProducts();
      return true;
    }
    return false;
  }

  Future<bool> updateProduct(Product product) async {
    final updated = await _productDao.updateProduct(product);
    if (updated > 0) {
      await loadProducts();
      return true;
    }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    final deleted = await _productDao.softDeleteProduct(id);
    if (deleted > 0) {
      await loadProducts();
      return true;
    }
    return false;
  }

  Future<void> addCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty || _categories.contains(trimmed)) return;
    await _categoryDao.insertCategory(trimmed);
    await loadCategories();
  }
}
