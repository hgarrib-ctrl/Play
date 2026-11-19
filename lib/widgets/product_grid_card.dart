import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/product.dart';
import '../services/currency_service.dart';

class ProductGridCard extends StatefulWidget {
  final Product product;
  final int currentCartQuantity;
  final VoidCallback onTap;

  const ProductGridCard({
    super.key,
    required this.product,
    this.currentCartQuantity = 0,
    required this.onTap,
  });

  @override
  State<ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<ProductGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
    widget.onTap();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return Icons.restaurant;
      case 'electronics':
        return Icons.devices_other;
      case 'accessories':
        return Icons.watch;
      case 'festive':
        return Icons.celebration;
      case 'clothing':
        return Icons.checkroom;
      case 'groceries':
        return Icons.local_grocery_store;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inCart = widget.currentCartQuantity > 0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: AppStyles.borderRadiusLarge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: inCart
                    ? (isDark
                        ? AppColors.electricBlue.withValues(alpha: 0.15)
                        : AppColors.electricBlue.withValues(alpha: 0.10))
                    : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
                borderRadius: AppStyles.borderRadiusLarge,
                border: Border.all(
                  color: inCart
                      ? AppColors.electricBlue
                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                  width: inCart ? 1.8 : 1.0,
                ),
                boxShadow: inCart ? AppStyles.glowShadowBlue : AppStyles.subtleShadowDark,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Image or Glass Placeholder
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppStyles.radiusLarge),
                            ),
                          ),
                          child: widget.product.imagePath != null &&
                                  File(widget.product.imagePath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppStyles.radiusLarge),
                                  ),
                                  child: Image.file(
                                    File(widget.product.imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    _getCategoryIcon(widget.product.category),
                                    size: 38,
                                    color: isDark
                                        ? AppColors.softCyan.withValues(alpha: 0.7)
                                        : AppColors.electricBlue.withValues(alpha: 0.7),
                                  ),
                                ),
                        ),
                      ),

                      // Product Details
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Tag
                                  Text(
                                    widget.product.category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: isDark
                                          ? AppColors.softCyan
                                          : AppColors.electricBlue,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Product Name
                                  Text(
                                    widget.product.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              // Price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    CurrencyService.format(
                                      widget.product.price,
                                      symbol: '₹',
                                      showDecimals: false,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: inCart
                                          ? (isDark ? AppColors.softCyan : AppColors.electricBlue)
                                          : (isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                  // Mini Quick Add Icon
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: inCart
                                          ? AppColors.electricBlue
                                          : (isDark
                                              ? AppColors.glassFillActiveDark
                                              : AppColors.glassFillActiveLight),
                                    ),
                                    child: Icon(
                                      inCart ? Icons.check : Icons.add,
                                      size: 14,
                                      color: inCart
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Cart Quantity Badge
                  if (inCart)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppStyles.glowShadowBlue,
                        ),
                        child: Text(
                          '${widget.currentCartQuantity} in bill',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
