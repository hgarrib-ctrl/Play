class ShopSettings {
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String shopGstin;
  final String currencySymbol;
  final String themeMode; // 'dark', 'light', 'system'
  final bool keepScreenAwake;
  final String receiptFooter;
  final String shopUpiId; // e.g. "kaku@upi" for dynamic prefilled QR
  final String? shopQrPath; // Optional path to custom uploaded QR image

  ShopSettings({
    this.shopName = 'QuickBill Store',
    this.shopAddress = '',
    this.shopPhone = '',
    this.shopGstin = '',
    this.currencySymbol = '₹',
    this.themeMode = 'dark',
    this.keepScreenAwake = true,
    this.receiptFooter = 'Thank you for shopping with us! Visit again.',
    this.shopUpiId = '',
    this.shopQrPath,
  });

  ShopSettings copyWith({
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? shopGstin,
    String? currencySymbol,
    String? themeMode,
    bool? keepScreenAwake,
    String? receiptFooter,
    String? shopUpiId,
    String? shopQrPath,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      shopGstin: shopGstin ?? this.shopGstin,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      shopUpiId: shopUpiId ?? this.shopUpiId,
      shopQrPath: shopQrPath ?? this.shopQrPath,
    );
  }
}
