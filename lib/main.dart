import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'constants/app_colors.dart';
import 'database/database_helper.dart';
import 'controllers/billing_controller.dart';
import 'controllers/calculator_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/settings_controller.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for Windows/Desktop/Test environments
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-initialize database
  await DatabaseHelper.instance.database;

  // Initialize Controllers
  final settingsController = SettingsController();
  await settingsController.init();

  final productController = ProductController();
  await productController.init();

  final billingController = BillingController();
  final calcController = CalculatorController();
  final historyController = HistoryController();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    QuickBillApp(
      settingsController: settingsController,
      productController: productController,
      billingController: billingController,
      calcController: calcController,
      historyController: historyController,
    ),
  );
}

class QuickBillApp extends StatelessWidget {
  final SettingsController settingsController;
  final ProductController productController;
  final BillingController billingController;
  final CalculatorController calcController;
  final HistoryController historyController;

  const QuickBillApp({
    super.key,
    required this.settingsController,
    required this.productController,
    required this.billingController,
    required this.calcController,
    required this.historyController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'QuickBill',
          debugShowCheckedModeBanner: false,
          themeMode: settingsController.themeMode,
          
          // Dark Theme (Default Glassmorphism or Diwali Festive Gold)
          darkTheme: settingsController.isDiwaliTheme
              ? ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: AppColors.diwaliBackground,
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.diwaliGoldAccent,
                    secondary: AppColors.diwaliHighlight,
                    surface: AppColors.diwaliSurface,
                    error: AppColors.coralRed,
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: AppColors.diwaliGoldAccent),
                    titleTextStyle: TextStyle(
                      color: AppColors.diwaliTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: AppColors.diwaliSurface,
                  ),
                  dividerColor: const Color(0x26FFB300),
                )
              : ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: AppColors.darkBackground,
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.electricBlue,
                    secondary: AppColors.softCyan,
                    surface: AppColors.darkSurface,
                    error: AppColors.coralRed,
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: Colors.white),
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  dialogTheme: const DialogThemeData(
                    backgroundColor: AppColors.darkSurface,
                  ),
                  dividerColor: const Color(0x1AFFFFFF),
                ),

          // Light Theme (Clean Frosted White)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.lightBackground,
            colorScheme: const ColorScheme.light(
              primary: AppColors.electricBlue,
              secondary: AppColors.softCyan,
              surface: AppColors.lightSurface,
              error: AppColors.coralRed,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
              titleTextStyle: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
            dividerColor: const Color(0x1F000000),
          ),

          home: MainNavigationScreen(
            billingController: billingController,
            productController: productController,
            calcController: calcController,
            historyController: historyController,
            settingsController: settingsController,
          ),
        );
      },
    );
  }
}
