import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_icons.dart';
import '../models/settings.dart';
import '../services/storage_service.dart';
import '../services/backup_sync_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../widgets/flat_card.dart';
import '../widgets/custom_badge.dart';

class SettingsBackupScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsBackupScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<SettingsBackupScreen> createState() => _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends State<SettingsBackupScreen> {
  final StorageService storage = StorageService();
  final BackupSyncService syncService = BackupSyncService();

  late TextEditingController _brandNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _stampNameController;
  final TextEditingController _jsonPasteController = TextEditingController();

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _brandNameController = TextEditingController(text: storage.settings.brandName);
    _phoneController = TextEditingController(text: storage.settings.phone);
    _addressController = TextEditingController(text: storage.settings.address);
    _stampNameController = TextEditingController(text: storage.settings.sellerStampName);
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stampNameController.dispose();
    _jsonPasteController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    storage.settings = StoreSettings(
      brandName: _brandNameController.text.trim().isEmpty ? 'بازرگانی' : _brandNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      sellerStampName: _stampNameController.text.trim(),
    );
    await storage.saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات با موفقیت ذخیره شد'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleExport() async {
    setState(() => _isExporting = true);
    final res = await syncService.exportDatabaseAndShare();
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
        ),
      );
    }
  }

  void _showImportOptions() async {
    final savedBackups = await syncService.getSavedBackupFiles();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'وارد کردن دیتابیس (Import)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Option 0: Native File Manager (Primary requested feature!)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.downloadCloud, color: AppColors.emerald),
                ),
                title: const Text('انتخاب فایل JSON از فایل‌منیجر گوشی', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.emerald)),
                subtitle: const Text('پوشه Downloads، حافظه داخلی، تلگرام یا کارت حافظه', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await syncService.pickFileWithNativeFileManager();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
                      ),
                    );
                    if (res.success) setState(() {});
                  }
                },
              ),
              const Divider(),
              // Option 1: Fast paste from clipboard
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.clipboardPaste, color: AppColors.primaryDark),
                ),
                title: const Text('چسباندن متن JSON از کلیپ‌بورد', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('متن فایل بکاپ وب را کپی کرده و اینجا لمس کنید', style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final data = await Clipboard.getData('text/plain');
                  final text = data?.text?.trim() ?? '';
                  if (text.isEmpty) {
                    _showPasteJsonDialog();
                  } else {
                    final res = await syncService.importDatabaseFromJsonString(text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.message),
                          backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
                        ),
                      );
                      if (res.success) setState(() {});
                    }
                  }
                },
              ),
              const Divider(),
              // Option 2: Enter manually in text box
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blueSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.edit3, color: AppColors.blue),
                ),
                title: const Text('ورود دستی متن JSON', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: const Text('مشاهده و ویرایش متن پیش از وارد کردن به سیستم', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPasteJsonDialog();
                },
              ),
              if (savedBackups.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'نسخه‌های پشتیبان ذخیره‌شده در گوشی:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.3),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: savedBackups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final b = savedBackups[idx];
                      return FlatCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final res = await syncService.importDatabaseFromFile(File(b.path));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
                              ),
                            );
                            if (res.success) setState(() {});
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.fileName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text(
                                    'حجم: ${PersianFormatter.toPersianDigits((b.sizeBytes / 1024).toStringAsFixed(1))} کیلوبایت',
                                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.repeat, size: 16, color: AppColors.primary),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleCopyJson() {
    final jsonStr = syncService.generateExportJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('کل متن دیتابیس با فرمت JSON در حافظه (کلیپ‌بورد) کپی شد.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showPasteJsonDialog() {
    _jsonPasteController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('چسباندن متن دیتابیس (JSON)'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'متن JSON خروجی گرفته شده از نسخه وب را در کادر زیر قرار دهید:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _jsonPasteController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: '{\n  "version": "2.0",\n  "products": [...]\n}',
                    hintStyle: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = _jsonPasteController.text.trim();
                if (text.isEmpty) return;

                Navigator.pop(ctx);
                final res = await syncService.importDatabaseFromJsonString(text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message),
                      backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
                    ),
                  );
                  if (res.success) {
                    setState(() {});
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('وارد کردن دیتابیس'),
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
      appBar: AppBar(
        title: const Text('تنظیمات و همگام‌سازی دیتابیس'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? LucideIcons.sun : LucideIcons.moon),
            tooltip: 'تغییر حالت شب و روز',
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline & Sync Banner
          FlatCard(
            backgroundColor: AppColors.primarySurface,
            borderColor: AppColors.primaryLight.withOpacity(0.3),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.repeat, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'همگام‌سازی کاملاً آفلاین با نسخه وب',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'بدون نیاز به اینترنت! می‌توانید اطلاعات فاکتورهای ثبت شده بیرون را استخراج (Export) کرده و در نسخه وب وارد (Import) فرمایید یا بالعکس.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMainLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Database Sync Actions Card
          FlatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'عملیات پشتیبان‌گیری و انتقال داده',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    CustomBadge(
                      text: '${PersianFormatter.toPersianDigits(storage.invoices.length)} فاکتور • ${PersianFormatter.toPersianDigits(storage.products.length)} کالا',
                      textColor: AppColors.primaryDark,
                      backgroundColor: AppColors.primarySurface,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.uploadCloud, size: 18),
                    label: const Text(
                      'استخراج دیتابیس جهت انتقال به نسخه وب (Export JSON)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Import Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showImportOptions,
                    icon: const Icon(LucideIcons.downloadCloud, size: 18),
                    label: const Text(
                      'وارد کردن فایل پشتیبان از وب به گوشی (Import JSON)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      side: BorderSide(color: isDark ? AppColors.borderDarkStrong : AppColors.borderLightStrong),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 10),

                // Clipboard Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _handleCopyJson,
                        icon: const Icon(LucideIcons.copy, size: 14),
                        label: const Text('کپی در کلیپ‌بورد', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _showPasteJsonDialog,
                        icon: const Icon(LucideIcons.clipboardPaste, size: 14),
                        label: const Text('چسباندن متن JSON', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Business & Store Settings
          FlatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مشخصات فروشگاه و بازرگانی',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(LucideIcons.save, size: 14),
                      label: const Text('ذخیره مشخصات', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(labelText: 'نام برند / فروشگاه'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'شماره تلفن تماس'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'آدرس دفتر مرکزی و انبار'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _stampNameController,
                  decoration: const InputDecoration(labelText: 'عنوان مهر و امضای فروشنده'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'سامانه اتوماسیون بازرگانی و انبارداری (نسخه اندروید)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                const SizedBox(height: 4),
                Text(
                  'نسخه ۱.۰.۰ • عملکرد ۱۰۰٪ آفلاین • سازگار با نسخه وب',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
