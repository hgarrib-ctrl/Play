import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../controllers/billing_controller.dart';
import '../controllers/calculator_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/settings_controller.dart';
import 'billing_screen.dart';
import 'products_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final BillingController billingController;
  final ProductController productController;
  final CalculatorController calcController;
  final HistoryController historyController;
  final SettingsController settingsController;

  const MainNavigationScreen({
    super.key,
    required this.billingController,
    required this.productController,
    required this.calcController,
    required this.historyController,
    required this.settingsController,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Tab 0: BILL (Default)

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BillingScreen(
        billingController: widget.billingController,
        productController: widget.productController,
        calcController: widget.calcController,
        settingsController: widget.settingsController,
      ),
      ProductsScreen(
        productController: widget.productController,
      ),
      HistoryScreen(
        historyController: widget.historyController,
        billingController: widget.billingController,
        settingsController: widget.settingsController,
        onNavigateToBilling: () => setState(() => _currentIndex = 0),
      ),
      SettingsScreen(
        settingsController: widget.settingsController,
        productController: widget.productController,
        historyController: widget.historyController,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xE6080D19) : const Color(0xF2FFFFFF),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                if (index == 2) {
                  widget.historyController.loadHistory();
                } else if (index == 1) {
                  widget.productController.loadProducts();
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.electricBlue,
              unselectedItemColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: [
                BottomNavigationBarItem(
                  icon: ListenableBuilder(
                    listenable: widget.billingController,
                    builder: (context, _) {
                      final count = widget.billingController.itemCount;
                      return Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count'),
                        backgroundColor: AppColors.electricBlue,
                        child: const Icon(Icons.point_of_sale_outlined),
                      );
                    },
                  ),
                  activeIcon: const Icon(Icons.point_of_sale),
                  label: 'BILL',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'PRODUCTS',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'HISTORY',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'SETTINGS',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
