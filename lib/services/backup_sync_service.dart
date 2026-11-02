import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/settings.dart';
import '../utils/persian_date_helper.dart';

class BackupSyncResult {
  final bool success;
  final String message;
  final int productsCount;
  final int invoicesCount;
  final int customersCount;

  BackupSyncResult({
    required this.success,
    required this.message,
    this.productsCount = 0,
    this.invoicesCount = 0,
    this.customersCount = 0,
  });
}

class BackupSyncService {
  final StorageService storage = StorageService();

  /// Export current database to a 100% web-compatible JSON string
  String generateExportJson() {
    final Map<String, dynamic> exportBundle = {
      'version': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'summary': {
        'productsCount': storage.products.length,
        'invoicesCount': storage.invoices.length,
        'draftsCount': storage.invoices.where((i) => i.isDraft).length,
        'salesCount': storage.invoices.where((i) => !i.isDraft && i.isSale).length,
        'purchasesCount': storage.invoices.where((i) => !i.isDraft && i.isPurchase).length,
        'customersCount': storage.customers.length,
        'paymentsCount': storage.payments.length,
        'returnsCount': storage.productReturns.length,
        'treasuryCount': storage.treasury.length,
        'categoriesCount': storage.categories.length,
      },
      'products': storage.products.map((p) => p.toJson()).toList(),
      'invoices': storage.invoices.map((i) => i.toJson()).toList(),
      'draftInvoices': storage.invoices.where((i) => i.isDraft).map((i) => i.toJson()).toList(),
      'customers': storage.customers.map((c) => c.toJson()).toList(),
      'payments': storage.payments.map((p) => p.toJson()).toList(),
      'customerPayments': storage.payments.map((p) => p.toJson()).toList(),
      'productReturns': storage.productReturns.map((r) => r.toJson()).toList(),
      'returns': storage.productReturns.map((r) => r.toJson()).toList(),
      'treasuryTransactions': storage.treasury.map((t) => t.toJson()).toList(),
      'treasury': storage.treasury.map((t) => t.toJson()).toList(),
      'liquidity': storage.treasury.map((t) => t.toJson()).toList(),
      'categories': storage.categories,
      'customCategories': storage.categories,
      'settings': storage.settings.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportBundle);
  }

  /// Export database to a local file and trigger system share sheet (Send via Bluetooth, Telegram, Save to Downloads, etc.)
  Future<BackupSyncResult> exportDatabaseAndShare() async {
    try {
      final jsonStr = generateExportJson();
      final dateStr = PersianDateHelper.getCurrentJalaliDate().replaceAll('/', '-');
      final timeStr = PersianDateHelper.getCurrentTime().replaceAll(':', '');
      final fileName = 'bazargani-backup-$dateStr-$timeStr.json';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonStr, encoding: utf8);

      final xFile = XFile(file.path, mimeType: 'application/json', name: fileName);
      await Share.shareXFiles([xFile], text: 'فایل پشتیبان دیتابیس بازرگانی و انبارداری (سازگار با نسخه وب)');

      return BackupSyncResult(
        success: true,
        message: 'فایل پشتیبان با موفقیت استخراج گردید.',
        productsCount: storage.products.length,
        invoicesCount: storage.invoices.length,
        customersCount: storage.customers.length,
      );
    } catch (e) {
      return BackupSyncResult(
        success: false,
        message: 'خطا در استخراج فایل پشتیبان: $e',
      );
    }
  }

  /// Import database from a JSON string (received from web app backup file or user pick)
  Future<BackupSyncResult> importDatabaseFromJsonString(String jsonContent) async {
    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded == null) {
        return BackupSyncResult(success: false, message: 'محتوای فایل خالی است.');
      }

      // Handle snapshot wrapper or direct bundle
      final Map<String, dynamic> bundle = (decoded is Map<String, dynamic> &&
              decoded['data'] != null &&
              decoded['data'] is Map<String, dynamic>)
          ? decoded['data'] as Map<String, dynamic>
          : decoded as Map<String, dynamic>;

      int importedProducts = 0;
      int importedInvoices = 0;
      int importedCustomers = 0;

      // 1. Products
      if (bundle['products'] != null && bundle['products'] is List) {
        final List<dynamic> prodList = bundle['products'];
        storage.products = prodList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        importedProducts = storage.products.length;
        await storage.saveProducts();
      }

      // 2. Invoices & Drafts
      List<Invoice> allInvoices = [];
      if (bundle['invoices'] != null && bundle['invoices'] is List) {
        final List<dynamic> invList = bundle['invoices'];
        allInvoices = invList.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
      }

      // Merge separate drafts if present
      final extraDrafts = bundle['draftInvoices'] ?? bundle['drafts'];
      if (extraDrafts is List) {
        for (final d in extraDrafts) {
          if (d is Map<String, dynamic>) {
            final draftInv = Invoice.fromJson(d);
            if (!allInvoices.any((i) => i.id == draftInv.id)) {
              allInvoices.add(draftInv.copyWith(isDraft: true));
            }
          }
        }
      }

      if (allInvoices.isNotEmpty) {
        storage.invoices = allInvoices;
        importedInvoices = allInvoices.length;
        await storage.saveInvoices();
      }

      // 3. Customers
      if (bundle['customers'] != null && bundle['customers'] is List) {
        final List<dynamic> custList = bundle['customers'];
        storage.customers = custList.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
        importedCustomers = storage.customers.length;
        await storage.saveCustomers();
      }

      // 4. Categories
      final cats = bundle['categories'] ?? bundle['customCategories'];
      if (cats is List) {
        storage.categories = cats.map((e) => e.toString()).toList();
        await storage.saveCategories();
      }

      // 5. Settings
      if (bundle['settings'] != null && bundle['settings'] is Map<String, dynamic>) {
        storage.settings = StoreSettings.fromJson(bundle['settings']);
        await storage.saveSettings();
      }

      return BackupSyncResult(
        success: true,
        message: 'دیتابیس با موفقیت بازگردانی شد ($importedProducts کالا، $importedInvoices فاکتور، $importedCustomers مشتری).',
        productsCount: importedProducts,
        invoicesCount: importedInvoices,
        customersCount: importedCustomers,
      );
    } catch (e) {
      return BackupSyncResult(
        success: false,
        message: 'خطا در پردازش فایل پشتیبان: $e',
      );
    }
  }

  /// Pick a JSON file from device storage and import it
  Future<BackupSyncResult> pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return BackupSyncResult(success: false, message: 'هیچ فایلی انتخاب نشد.');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);
      return await importDatabaseFromJsonString(content);
    } catch (e) {
      return BackupSyncResult(
        success: false,
        message: 'خطا در باز کردن فایل: $e',
      );
    }
  }
}
