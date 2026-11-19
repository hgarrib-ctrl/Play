import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/product_controller.dart';
import '../models/product.dart';
import '../services/currency_service.dart';
import '../services/image_service.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/category_chips.dart';

class ProductsScreen extends StatefulWidget {
  final ProductController productController;

  const ProductsScreen({
    super.key,
    required this.productController,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ImageService _imageService = ImageService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditProductModal([Product? existingProduct]) {
    final nameController = TextEditingController(text: existingProduct?.name ?? '');
    final priceController = TextEditingController(
      text: existingProduct != null ? existingProduct.price.toStringAsFixed(0) : '',
    );
    String selectedCat = existingProduct?.category ?? 'Kitchen';
    String? currentImagePath = existingProduct?.imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text(
                    existingProduct == null ? 'Add New Product' : 'Edit Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Picker Section
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (bctx) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take Photo with Camera'),
                                  onTap: () async {
                                    Navigator.pop(bctx);
                                    final path = await _imageService.pickAndSaveImage(
                                      source: ImageSource.camera,
                                    );
                                    if (path != null) {
                                      setModalState(() => currentImagePath = path);
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () async {
                                    Navigator.pop(bctx);
                                    final path = await _imageService.pickAndSaveImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (path != null) {
                                      setModalState(() => currentImagePath = path);
                                    }
                                  },
                                ),
                                if (currentImagePath != null)
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: AppColors.coralRed),
                                    title: const Text('Remove Image', style: TextStyle(color: AppColors.coralRed)),
                                    onTap: () {
                                      Navigator.pop(bctx);
                                      setModalState(() => currentImagePath = null);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                          borderRadius: AppStyles.borderRadiusMedium,
                          border: Border.all(
                            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          ),
                        ),
                        child: currentImagePath != null && File(currentImagePath!).existsSync()
                            ? ClipRRect(
                                borderRadius: AppStyles.borderRadiusMedium,
                                child: Image.file(File(currentImagePath!), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Photo (Opt)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name Field (Mandatory)
                  GlassTextField(
                    controller: nameController,
                    labelText: 'Product Name *',
                    hintText: 'e.g. Copper Water Jug',
                    prefixIcon: Icons.shopping_bag_outlined,
                    autofocus: existingProduct == null,
                  ),

                  const SizedBox(height: 12),

                  // Price Field (Mandatory)
                  GlassTextField(
                    controller: priceController,
                    labelText: 'Selling Price (₹) *',
                    hintText: 'e.g. 450',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.currency_rupee,
                  ),

                  const SizedBox(height: 14),

                  // Category Dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: AppStyles.borderRadiusMedium,
                        borderSide: BorderSide(
                          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                        ),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.productController.categories.contains(selectedCat)
                            ? selectedCat
                            : widget.productController.categories.firstWhere((c) => c != 'All', orElse: () => 'Other'),
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                        items: widget.productController.categories
                            .where((c) => c != 'All')
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCat = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  GlassButton(
                    text: existingProduct == null ? 'Save Product' : 'Update Product',
                    icon: Icons.check,
                    variant: GlassButtonVariant.primary,
                    isExpanded: true,
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final price = double.tryParse(priceController.text.trim());

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a product name')),
                        );
                        return;
                      }

                      if (price == null || price < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid price')),
                        );
                        return;
                      }

                      if (existingProduct == null) {
                        await widget.productController.addProduct(
                          name: name,
                          price: price,
                          category: selectedCat,
                          imagePath: currentImagePath,
                        );
                      } else {
                        await widget.productController.updateProduct(
                          existingProduct.copyWith(
                            name: name,
                            price: price,
                            category: selectedCat,
                            imagePath: currentImagePath,
                          ),
                        );
                      }

                      if (context.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dialogDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Delete "${product.name}"?',
            style: TextStyle(
              color: dialogDark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will remove the product from future billing. Past bills containing this product will not be affected.',
            style: TextStyle(
              color: dialogDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: dialogDark ? Colors.white70 : Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coralRed,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
              ),
              onPressed: () {
                widget.productController.deleteProduct(product.id!);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Product Catalogue', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.electricBlue),
            tooltip: 'Add Product',
            onPressed: () => _showAddOrEditProductModal(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassTextField(
              controller: _searchController,
              hintText: 'Search products by name...',
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Sub-Categorized Tabs for Product Catalogue (Independent from Billing)
          ListenableBuilder(
            listenable: widget.productController,
            builder: (context, _) {
              return CategoryChips(
                categories: widget.productController.categories,
                selectedCategory: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              );
            },
          ),
          const SizedBox(height: 6),

          Expanded(
            child: ListenableBuilder(
              listenable: widget.productController,
              builder: (context, _) {
                final allProducts = widget.productController.allProducts;
                final query = _searchController.text.trim().toLowerCase();

                final products = allProducts.where((p) {
                  if (query.isNotEmpty) {
                    final matchesName = p.name.toLowerCase().contains(query);
                    final matchesCat = p.category.toLowerCase().contains(query);
                    if (!matchesName && !matchesCat) return false;
                  }
                  if (_selectedCategory == 'All') return true;
                  return p.category.toLowerCase() == _selectedCategory.toLowerCase();
                }).toList();
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 54,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 12),
                        const Text('No products available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        GlassButton(
                          text: 'Add First Product',
                          icon: Icons.add,
                          onPressed: () => _showAddOrEditProductModal(),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return ClipRRect(
                      borderRadius: AppStyles.borderRadiusMedium,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                          borderRadius: AppStyles.borderRadiusMedium,
                          border: Border.all(
                            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Product Image or Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: product.imagePath != null && File(product.imagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(File(product.imagePath!), fit: BoxFit.cover),
                                    )
                                  : Icon(
                                      Icons.inventory_2,
                                      size: 26,
                                      color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                                    ),
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.glassFillActiveDark : AppColors.glassFillActiveLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          product.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyService.format(product.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.emeraldGreen : const Color(0xFF0F9D58),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: AppColors.electricBlue,
                              onPressed: () => _showAddOrEditProductModal(product),
                            ),

                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.coralRed,
                              onPressed: () => _confirmDelete(product),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.electricBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _showAddOrEditProductModal(),
      ),
    );
  }
}
