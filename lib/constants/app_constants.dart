class AppConstants {
  static const String appName = 'QuickBill';
  static const String appTagline = 'Lightning Fast Shop Billing';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultShopName = 'QuickBill Store';

  // Seed Categories
  static const List<String> defaultCategories = [
    'All',
    'Kitchen',
    'Electronics',
    'Accessories',
    'Clothing',
    'Groceries',
    'Festive',
    'Other',
  ];

  // Pref Keys
  static const String prefShopName = 'qb_shop_name';
  static const String prefShopAddress = 'qb_shop_address';
  static const String prefShopPhone = 'qb_shop_phone';
  static const String prefShopGstin = 'qb_shop_gstin';
  static const String prefCurrency = 'qb_currency';
  static const String prefThemeMode = 'qb_theme_mode'; // 'dark', 'light', 'system'
  static const String prefKeepScreenAwake = 'qb_keep_awake';
  static const String prefReceiptFooter = 'qb_receipt_footer';
  static const String prefShopUpiId = 'qb_shop_upi_id';
  static const String prefShopQrPath = 'qb_shop_qr_path';
  static const String prefInitialSeedDone = 'qb_seed_done_v1';
}
