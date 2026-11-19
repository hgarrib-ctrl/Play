import 'package:intl/intl.dart';

class CurrencyService {
  /// Formats amount in Indian numbering system: e.g., ₹1,25,500.00 or ₹250.00
  static String format(
    double amount, {
    String symbol = '₹',
    bool showDecimals = true,
  }) {
    try {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: symbol.isNotEmpty ? '$symbol ' : '',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return formatter.format(amount);
    } catch (_) {
      // Fallback manual Indian numbering system
      final isNegative = amount < 0;
      final absAmount = amount.abs();
      final fixed = absAmount.toStringAsFixed(showDecimals ? 2 : 0);
      final parts = fixed.split('.');
      String integerPart = parts[0];
      final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

      if (integerPart.length > 3) {
        final lastThree = integerPart.substring(integerPart.length - 3);
        final remaining = integerPart.substring(0, integerPart.length - 3);
        
        // Group remaining into pairs of 2
        final buffer = StringBuffer();
        for (int i = 0; i < remaining.length; i++) {
          if (i > 0 && (remaining.length - i) % 2 == 0) {
            buffer.write(',');
          }
          buffer.write(remaining[i]);
        }
        integerPart = '$buffer,$lastThree';
      }

      final sign = isNegative ? '-' : '';
      final sym = symbol.isNotEmpty ? '$symbol ' : '';
      return '$sign$sym$integerPart$decimalPart';
    }
  }

  /// Compact Indian format for tags/chips: e.g. ₹1.25L, ₹50k, ₹500
  static String formatCompact(double amount, {String symbol = '₹'}) {
    final sym = symbol.isNotEmpty ? symbol : '';
    if (amount >= 10000000) {
      return '$sym${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$sym${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$sym${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return '$sym${amount.toStringAsFixed(0)}';
    }
  }
}
