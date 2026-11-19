import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../constants/app_constants.dart';
import '../models/shop_settings.dart';
import '../services/backup_service.dart';

class SettingsController extends ChangeNotifier {
  final BackupService _backupService = BackupService();
  ShopSettings _settings = ShopSettings();

  ShopSettings get settings => _settings;
  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system; // Follow phone's dynamic dark/light mode
      case 'diwali':
        return ThemeMode.dark; // Special Diwali festive gold theme
      default:
        return ThemeMode.dark;
    }
  }

  bool get isDiwaliTheme => _settings.themeMode == 'diwali';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final keepAwake = prefs.getBool(AppConstants.prefKeepScreenAwake) ?? true;
    _settings = ShopSettings(
      shopName: prefs.getString(AppConstants.prefShopName) ?? AppConstants.defaultShopName,
      shopAddress: prefs.getString(AppConstants.prefShopAddress) ?? '',
      shopPhone: prefs.getString(AppConstants.prefShopPhone) ?? '',
      shopGstin: prefs.getString(AppConstants.prefShopGstin) ?? '',
      currencySymbol: prefs.getString(AppConstants.prefCurrency) ?? AppConstants.defaultCurrencySymbol,
      themeMode: prefs.getString(AppConstants.prefThemeMode) ?? 'dark',
      keepScreenAwake: keepAwake,
      receiptFooter: prefs.getString(AppConstants.prefReceiptFooter) ??
          'Thank you for shopping with us! Visit again.',
      shopUpiId: prefs.getString(AppConstants.prefShopUpiId) ?? '',
      shopQrPath: prefs.getString(AppConstants.prefShopQrPath),
    );

    try {
      await WakelockPlus.toggle(enable: keepAwake);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> updateSettings({
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
  }) async {
    _settings = _settings.copyWith(
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopGstin: shopGstin,
      currencySymbol: currencySymbol,
      themeMode: themeMode,
      keepScreenAwake: keepScreenAwake,
      receiptFooter: receiptFooter,
      shopUpiId: shopUpiId,
      shopQrPath: shopQrPath,
    );
    notifyListeners();

    if (keepScreenAwake != null) {
      try {
        await WakelockPlus.toggle(enable: keepScreenAwake);
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    if (shopName != null) await prefs.setString(AppConstants.prefShopName, shopName);
    if (shopAddress != null) await prefs.setString(AppConstants.prefShopAddress, shopAddress);
    if (shopPhone != null) await prefs.setString(AppConstants.prefShopPhone, shopPhone);
    if (shopGstin != null) await prefs.setString(AppConstants.prefShopGstin, shopGstin);
    if (currencySymbol != null) await prefs.setString(AppConstants.prefCurrency, currencySymbol);
    if (themeMode != null) await prefs.setString(AppConstants.prefThemeMode, themeMode);
    if (keepScreenAwake != null) await prefs.setBool(AppConstants.prefKeepScreenAwake, keepScreenAwake);
    if (receiptFooter != null) await prefs.setString(AppConstants.prefReceiptFooter, receiptFooter);
    if (shopUpiId != null) await prefs.setString(AppConstants.prefShopUpiId, shopUpiId);
    if (shopQrPath != null) await prefs.setString(AppConstants.prefShopQrPath, shopQrPath);
  }

  Future<String> exportBackup() async {
    return await _backupService.exportBackupJson();
  }

  Future<bool> restoreBackup(String jsonStr) async {
    final success = await _backupService.restoreFromJson(jsonStr);
    return success;
  }

  Future<bool> clearAllData() async {
    final success = await _backupService.clearAllData();
    return success;
  }
}
