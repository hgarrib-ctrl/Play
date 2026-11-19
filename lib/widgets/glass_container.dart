import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Gradient? borderGradient;
  final Border? border;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.blur = AppStyles.glassBlur,
    this.color,
    this.gradient,
    this.borderGradient,
    this.border,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppStyles.borderRadiusLarge;

    final defaultFill = isDark ? AppColors.glassFillDark : AppColors.glassFillLight;
    final defaultShadows = isDark ? AppStyles.subtleShadowDark : AppStyles.subtleShadowLight;

    Widget container = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? (gradient == null ? defaultFill : null),
            gradient: gradient,
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  width: 1.0,
                ),
            boxShadow: shadows ?? defaultShadows,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      container = Padding(padding: margin!, child: container);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }

    return container;
  }
}
