import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum GlassButtonVariant {
  primary,
  secondary,
  success,
  danger,
  ghost,
}

class GlassButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.isExpanded = false,
    this.padding,
    this.fontSize,
    this.isLoading = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Gradient? gradient;
    Color? backgroundColor;
    Color textColor = Colors.white;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case GlassButtonVariant.primary:
        gradient = AppColors.primaryGradient;
        textColor = Colors.white;
        shadows = AppStyles.glowShadowBlue;
        break;
      case GlassButtonVariant.success:
        gradient = AppColors.accentGreenGradient;
        textColor = const Color(0xFF042F1A);
        shadows = AppStyles.glowShadowGreen;
        break;
      case GlassButtonVariant.danger:
        backgroundColor = AppColors.coralRed.withValues(alpha: 0.85);
        textColor = Colors.white;
        break;
      case GlassButtonVariant.secondary:
        backgroundColor = isDark ? AppColors.glassFillActiveDark : AppColors.glassFillActiveLight;
        textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        border = Border.all(
          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          width: 1,
        );
        break;
      case GlassButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.electricBlue : AppColors.electricBlue;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: textColor,
              fontSize: widget.fontSize ?? 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? (_) => _animController.forward() : null,
        onTapUp: widget.onPressed != null ? (_) => _animController.reverse() : null,
        onTapCancel: widget.onPressed != null ? () => _animController.reverse() : null,
        onTap: widget.onPressed,
        child: ClipRRect(
          borderRadius: AppStyles.borderRadiusMedium,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                gradient: gradient,
                color: backgroundColor,
                borderRadius: AppStyles.borderRadiusMedium,
                border: border,
                boxShadow: shadows,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
