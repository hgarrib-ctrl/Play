import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/billing_controller.dart';
import '../controllers/calculator_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/settings_controller.dart';
import '../database/bill_dao.dart';
import '../services/currency_service.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/cart_bottom_sheet.dart';
import '../widgets/calculator_panel.dart';
import '../widgets/exchange_panel.dart';
import '../widgets/glass_text_field.dart';
import 'digital_bill_screen.dart';

class BillingScreen extends StatefulWidget {
  final BillingController billingController;
  final ProductController productController;
  final CalculatorController calcController;
  final SettingsController settingsController;

  const BillingScreen({
    super.key,
    required this.billingController,
    required this.productController,
    required this.calcController,
    required this.settingsController,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BillDao _billDao = BillDao();
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Independent Category State for Billing Screen (Does not interfere with Products tab)
  String _selectedCategory = 'All';
  List<String> _topDemandedNames = [];

  @override
  void initState() {
    super.initState();
    _loadTopDemanded();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _loadTopDemanded() async {
    try {
      final names = await _billDao.getTopDemandedProductNames(limit: 12);
      if (mounted) setState(() => _topDemandedNames = names);
    } catch (_) {}
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: widget.billingController,
        builder: (context, _) => CartBottomSheet(
          billingController: widget.billingController,
          onOpenCalculator: () {
            Navigator.pop(ctx);
            _showCalculatorSheet();
          },
          onCompleteBill: () {
            Navigator.pop(ctx);
            _promptBillNameAndComplete();
          },
          onOpenExchange: () {
            Navigator.pop(ctx);
            if (!widget.billingController.isExchangeMode) {
              widget.billingController.toggleExchangeMode(true);
            }
            _showExchangeSheet();
          },
        ),
      ),
    );
  }

  void _showCalculatorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CalculatorPanel(
        calcController: widget.calcController,
        billingController: widget.billingController,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showExchangeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: widget.billingController,
        builder: (context, _) => ExchangePanel(
          billingController: widget.billingController,
          onDismiss: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  // Customer Details Modal with SKIP Button (PART 7 & 9)
  void _promptBillNameAndComplete() {
    if (widget.billingController.items.isEmpty &&
        (!widget.billingController.isExchangeMode || widget.billingController.returnedItemValue <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product first.'),
          backgroundColor: AppColors.coralRed,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: widget.billingController.billName ?? '');
    final phoneController = TextEditingController(text: widget.billingController.customerPhone ?? '');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Customer Details (Optional)',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add customer name & mobile number to differentiate records, or tap SKIP to proceed immediately.',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              GlassTextField(
                controller: nameController,
                hintText: 'Customer Name (e.g. Rahul)',
                prefixIcon: Icons.person_outline,
                autofocus: true,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: phoneController,
                hintText: 'Customer Mobile (e.g. 98787616)',
                prefixIcon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            // SKIP BUTTON (Rush hour speed)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.billingController.setCustomerDetails(name: null, phone: null);
                _openDigitalBillScreen();
              },
              child: Text(
                'SKIP',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // CONTINUE BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                Navigator.pop(ctx);
                widget.billingController.setCustomerDetails(
                  name: name.isNotEmpty ? name : null,
                  phone: phone.isNotEmpty ? phone : null,
                );
                _openDigitalBillScreen();
              },
              child: const Text(
                'CONTINUE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDigitalBillScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DigitalBillScreen(
          billingController: widget.billingController,
          settingsController: widget.settingsController,
        ),
      ),
    ).then((_) {
      // Refresh top demanded products after bill completes
      _loadTopDemanded();
    });
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Add Custom Category',
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 16),
          ),
          content: GlassTextField(
            controller: catController,
            hintText: 'Category Name',
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
              onPressed: () {
                final val = catController.text.trim();
                if (val.isNotEmpty) {
                  widget.productController.addCategory(val);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add Category', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('EEE, dd MMM • hh:mm a');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (App Name, Date, New Bill, Calculator, Exchange)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'QuickBill',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Live Rush Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FAST POS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeFormat.format(_currentTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Quick Calculator & New Bill Action
                  Row(
                    children: [
                      // Independent / Bill Calculator Icon Button
                      IconButton(
                        icon: const Icon(Icons.calculate_outlined, color: AppColors.softCyan),
                        tooltip: 'Open Calculator',
                        onPressed: _showCalculatorSheet,
                      ),

                      // New Bill Action (Instant Reset)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.coralRed),
                        tooltip: 'New Bill',
                        onPressed: () {
                          if (widget.billingController.items.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                final dialogDark = Theme.of(ctx).brightness == Brightness.dark;
                                return AlertDialog(
                                  backgroundColor: dialogDark ? AppColors.darkSurface : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
                                  title: Text(
                                    'Start New Bill?',
                                    style: TextStyle(
                                      color: dialogDark ? Colors.white : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  content: Text(
                                    'Clear current items and start a fresh bill?',
                                    style: TextStyle(
                                      color: dialogDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: dialogDark ? Colors.white70 : Colors.black54),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.coralRed,
                                        shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                                      ),
                                      onPressed: () {
                                        widget.billingController.clearBill();
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('New Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            widget.billingController.clearBill();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Instant Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GlassTextField(
                controller: _searchController,
                hintText: 'Search products by name or category...',
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

            const SizedBox(height: 6),

            // Horizontal Category Selector (Independent for Billing)
            ListenableBuilder(
              listenable: widget.productController,
              builder: (context, _) {
                final billingCategories = [
                  'All',
                  '🔥 Most Demanded',
                  ...widget.productController.categories.where((c) => c != 'All'),
                ];
                return CategoryChips(
                  categories: billingCategories,
                  selectedCategory: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                  onAddCategory: _showAddCategoryDialog,
                );
              },
            ),

            const SizedBox(height: 8),

            // Product Grid
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([widget.productController, widget.billingController]),
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
                    if (_selectedCategory == '🔥 Most Demanded') {
                      if (_topDemandedNames.isNotEmpty) {
                        return _topDemandedNames.contains(p.name);
                      }
                      return p.id != null && p.id! <= 6;
                    }
                    return p.category.toLowerCase() == _selectedCategory.toLowerCase();
                  }).toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory == '🔥 Most Demanded'
                                ? 'No demand history yet'
                                : 'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCategory == '🔥 Most Demanded'
                                ? 'Complete a few bills to see your top selling items here automatically.'
                                : 'Try a different search term or add products in Products tab',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75, // Ample vertical height to eliminate bottom overflow
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      // Find how many of this product are in cart
                      final cartQty = widget.billingController.items
                          .where((i) => i.productId == product.id)
                          .fold(0, (sum, i) => sum + i.quantity);

                      return ProductGridCard(
                        product: product,
                        currentCartQuantity: cartQty,
                        onTap: () => widget.billingController.addProduct(product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Fixed / Floating Glass Bill Summary Bar at Bottom
      bottomSheet: ListenableBuilder(
        listenable: widget.billingController,
        builder: (context, _) {
          final count = widget.billingController.itemCount;
          final total = widget.billingController.finalTotal;
          final isExchange = widget.billingController.isExchangeMode;
          final isRefundable = widget.billingController.isRefundable;

          if (count == 0 && (!isExchange || widget.billingController.returnedItemValue <= 0)) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: _showCartSheet,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xF2101A2C) : const Color(0xF2FFFFFF),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    border: Border.all(
                      color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                      width: 1,
                    ),
                    boxShadow: AppStyles.glowShadowBlue,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Item count & Total
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isExchange
                                      ? (isRefundable ? 'OWED TO CUSTOMER' : 'EXCHANGE PAYABLE')
                                      : '$count ${count == 1 ? 'ITEM' : 'ITEMS'} IN BILL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: isExchange
                                        ? (isRefundable ? AppColors.amberOrange : AppColors.softCyan)
                                        : AppColors.textSecondaryDark,
                                  ),
                                ),
                                Text(
                                  CurrencyService.format(total),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: isRefundable
                                        ? AppColors.amberOrange
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Right: View Bill & Quick Complete Button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up, color: AppColors.softCyan),
                              onPressed: _showCartSheet,
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emeraldGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                              ),
                              onPressed: _promptBillNameAndComplete,
                              child: const Text(
                                'Generate Bill',
                                style: TextStyle(
                                  color: Color(0xFF042F1A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
