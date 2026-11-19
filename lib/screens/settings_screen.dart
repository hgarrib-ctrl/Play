import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../controllers/settings_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/history_controller.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_text_field.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController settingsController;
  final ProductController productController;
  final HistoryController historyController;

  const SettingsScreen({
    super.key,
    required this.settingsController,
    required this.productController,
    required this.historyController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _gstinController;
  late TextEditingController _footerController;
  late TextEditingController _upiController;
  String? _qrPath;

  @override
  void initState() {
    super.initState();
    final s = widget.settingsController.settings;
    _nameController = TextEditingController(text: s.shopName);
    _addressController = TextEditingController(text: s.shopAddress);
    _phoneController = TextEditingController(text: s.shopPhone);
    _gstinController = TextEditingController(text: s.shopGstin);
    _footerController = TextEditingController(text: s.receiptFooter);
    _upiController = TextEditingController(text: s.shopUpiId);
    _qrPath = s.shopQrPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _footerController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _qrPath = picked.path);
    }
  }

  void _saveShopProfile() {
    widget.settingsController.updateSettings(
      shopName: _nameController.text.trim(),
      shopAddress: _addressController.text.trim(),
      shopPhone: _phoneController.text.trim(),
      shopGstin: _gstinController.text.trim(),
      receiptFooter: _footerController.text.trim(),
      shopUpiId: _upiController.text.trim(),
      shopQrPath: _qrPath,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop settings updated!'),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
  }

  String _getThemeDescription(String mode) {
    switch (mode) {
      case 'system':
        return 'Follows phone dynamic dark / light mode';
      case 'light':
        return 'Light Frost frosted-glass minimal';
      case 'diwali':
        return 'Diwali Festive Gold & Royal Amber Diya glow';
      default:
        return 'Deep Midnight Navy Glassmorphism';
    }
  }

  void _showBackupExportDialog() async {
    final jsonStr = await widget.settingsController.exportBackup();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Data Backup (JSON)',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your entire database (products, categories, past bills) has been exported as JSON. You can copy it to clipboard or save it.',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonStr,
                    style: TextStyle(
                      color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue),
              icon: const Icon(Icons.copy, size: 16, color: Colors.white),
              label: const Text('Copy to Clipboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup JSON copied to clipboard!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Text(
            'Restore from JSON Backup',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your valid QuickBill JSON backup string below:',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: controller,
                hintText: '{"app": "QuickBill", ...}',
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amberOrange),
              onPressed: () async {
                final jsonText = controller.text.trim();
                if (jsonText.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  final success = await widget.settingsController.restoreBackup(jsonText);
                  if (success) {
                    await widget.productController.init();
                    await widget.historyController.loadHistory();
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Database restored successfully!'),
                        backgroundColor: AppColors.emeraldGreen,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to restore. Invalid JSON format.'),
                        backgroundColor: AppColors.coralRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Restore Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: const Text('Clear All Application Data?', style: TextStyle(color: AppColors.coralRed, fontWeight: FontWeight.w700)),
          content: Text(
            'This will permanently delete all products, categories, and past billing history. This action cannot be reversed!',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralRed),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await widget.settingsController.clearAllData();
                await widget.productController.init();
                await widget.historyController.loadHistory();
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All local application data cleared.'),
                    backgroundColor: AppColors.coralRed,
                  ),
                );
              },
              child: const Text('Clear All Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Shop Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Profile Card
            Text(
              'Shop Information (Receipt Details)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                borderRadius: AppStyles.borderRadiusMedium,
                border: Border.all(color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                  GlassTextField(
                    controller: _nameController,
                    labelText: 'Shop / Business Name',
                    prefixIcon: Icons.storefront,
                  ),
                  const SizedBox(height: 10),
                  GlassTextField(
                    controller: _addressController,
                    labelText: 'Shop Address / Market Location',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _phoneController,
                          labelText: 'Contact Phone',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassTextField(
                          controller: _gstinController,
                          labelText: 'GSTIN (Optional)',
                          prefixIcon: Icons.receipt_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GlassTextField(
                    controller: _footerController,
                    labelText: 'Receipt Footer Note',
                    prefixIcon: Icons.notes,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 12),

                  // UPI ID for Dynamic QR with auto-filled amount
                  GlassTextField(
                    controller: _upiController,
                    labelText: 'Shop UPI ID (for auto-filling amount)',
                    hintText: 'e.g. 98787616@paytm or shop@upi',
                    prefixIcon: Icons.qr_code,
                  ),
                  const SizedBox(height: 10),

                  // Optional Static QR code uploader
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.softCyan : AppColors.electricBlue,
                            side: BorderSide(
                              color: isDark ? AppColors.softCyan : AppColors.electricBlue,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(_qrPath != null ? 'Change QR Image' : 'Upload Shop QR Image'),
                          onPressed: _pickQrImage,
                        ),
                      ),
                      if (_qrPath != null) ...[
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_qrPath!),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.coralRed, size: 20),
                          tooltip: 'Remove QR image',
                          onPressed: () => setState(() => _qrPath = null),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),
                  GlassButton(
                    text: 'Save Shop Profile',
                    icon: Icons.save_outlined,
                    variant: GlassButtonVariant.primary,
                    isExpanded: true,
                    onPressed: _saveShopProfile,
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 24),

            // Theme & Preferences
            Text(
              'Appearance & Behavior',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                borderRadius: AppStyles.borderRadiusMedium,
                border: Border.all(color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                  // Theme Selection
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      _getThemeDescription(widget.settingsController.settings.themeMode),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: DropdownButton<String>(
                      value: widget.settingsController.settings.themeMode,
                      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('System Auto')),
                        DropdownMenuItem(value: 'dark', child: Text('Dark Navy')),
                        DropdownMenuItem(value: 'light', child: Text('Light Frost')),
                        DropdownMenuItem(value: 'diwali', child: Text('Diwali Gold 🪔')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          widget.settingsController.updateSettings(themeMode: val);
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12),

                  // Currency Symbol
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Default: INR (₹)', style: TextStyle(fontSize: 12)),
                    trailing: Text(
                      widget.settingsController.settings.currencySymbol,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.softCyan),
                    ),
                  ),
                  const Divider(color: Colors.white12),

                  // Screen awake
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Keep Screen Awake', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Prevents phone lock during festival rush hours', style: TextStyle(fontSize: 12)),
                    value: widget.settingsController.settings.keepScreenAwake,
                    activeThumbColor: AppColors.emeraldGreen,
                    onChanged: (val) {
                      widget.settingsController.updateSettings(keepScreenAwake: val);
                    },
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 24),

            // Backup & Restore
            Text(
              'Data Management & Backup',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                borderRadius: AppStyles.borderRadiusMedium,
                border: Border.all(color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.softCyan,
                            side: const BorderSide(color: AppColors.softCyan),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                          ),
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Backup (JSON)'),
                          onPressed: _showBackupExportDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.electricBlue,
                            side: const BorderSide(color: AppColors.electricBlue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusMedium),
                          ),
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('Restore (JSON)'),
                          onPressed: _showRestoreDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.coralRed),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear All Application Data (Reset)', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: _confirmClearData,
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                'QuickBill v1.0.0 • Offline First • High Speed POS',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
