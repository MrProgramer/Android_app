import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/settings.dart';
import '../models/return_item.dart';
import '../models/treasury.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String keyProducts = 'bazargani_products_v5';
  static const String keyInvoices = 'bazargani_invoices_v6';
  static const String keyCustomers = 'bazargani_customers_v6';
  static const String keyPayments = 'bazargani_payments_v2';
  static const String keySettings = 'bazargani_settings_v4';
  static const String keyReturns = 'bazargani_returns_v2';
  static const String keyTreasury = 'bazargani_treasury_v1';
  static const String keyCategories = 'bazargani_inventory_categories';

  SharedPreferences? _prefs;

  List<Product> products = [];
  List<Invoice> invoices = [];
  List<Customer> customers = [];
  List<CustomerPayment> payments = [];
  List<ProductReturn> productReturns = [];
  List<TreasuryTransaction> treasury = [];
  List<String> categories = ['عمومی', 'آبنبات', 'لواشک', 'بیسکویت', 'شکلات', 'کیک'];
  StoreSettings settings = StoreSettings();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadAll();
  }

  Future<void> loadAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    // 1. Products
    final prodStr = prefs.getString(keyProducts);
    if (prodStr != null) {
      try {
        final List<dynamic> list = jsonDecode(prodStr);
        products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        products = _initialProducts();
      }
    } else {
      products = _initialProducts();
      await saveProducts();
    }

    // 2. Customers
    final custStr = prefs.getString(keyCustomers);
    if (custStr != null) {
      try {
        final List<dynamic> list = jsonDecode(custStr);
        customers = list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        customers = _initialCustomers();
      }
    } else {
      customers = _initialCustomers();
      await saveCustomers();
    }

    // 3. Invoices
    final invStr = prefs.getString(keyInvoices);
    if (invStr != null) {
      try {
        final List<dynamic> list = jsonDecode(invStr);
        invoices = list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        invoices = [];
      }
    } else {
      invoices = [];
    }

    // 4. Payments
    final payStr = prefs.getString(keyPayments);
    if (payStr != null) {
      try {
        final List<dynamic> list = jsonDecode(payStr);
        payments = list.map((e) => CustomerPayment.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        payments = [];
      }
    }

    // 5. Settings
    final setStr = prefs.getString(keySettings);
    if (setStr != null) {
      try {
        settings = StoreSettings.fromJson(jsonDecode(setStr));
      } catch (e) {
        settings = StoreSettings();
      }
    }

    // 6. Categories
    final catStr = prefs.getString(keyCategories);
    if (catStr != null) {
      try {
        final List<dynamic> list = jsonDecode(catStr);
        categories = list.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    // Extract any unique categories from existing products
    for (final p in products) {
      if (p.category.isNotEmpty && !categories.contains(p.category)) {
        categories.add(p.category);
      }
    }
  }

  Future<void> saveProducts() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(keyProducts, jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  Future<void> saveInvoices() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(keyInvoices, jsonEncode(invoices.map((i) => i.toJson()).toList()));
  }

  Future<void> saveCustomers() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(keyCustomers, jsonEncode(customers.map((c) => c.toJson()).toList()));
  }

  Future<void> savePayments() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(keyPayments, jsonEncode(payments.map((p) => p.toJson()).toList()));
  }

  Future<void> saveSettings() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(keySettings, jsonEncode(settings.toJson()));
  }

  Future<void> saveCategories() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(keyCategories, jsonEncode(categories));
  }

  // --- Product Operations ---
  Future<void> addProduct(Product product) async {
    products.insert(0, product);
    if (!categories.contains(product.category)) {
      categories.add(product.category);
      await saveCategories();
    }
    await saveProducts();
  }

  Future<void> updateProduct(Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      if (!categories.contains(product.category)) {
        categories.add(product.category);
        await saveCategories();
      }
      await saveProducts();
    }
  }

  Future<void> deleteProduct(String productId) async {
    products.removeWhere((p) => p.id == productId);
    await saveProducts();
  }

  Future<void> restockProduct(String productId, int addPieces, {double? newPurchasePrice}) async {
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = products[index];
      products[index] = p.copyWith(
        stockPieces: p.stockPieces + addPieces,
        purchasePrice: newPurchasePrice ?? p.purchasePrice,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await saveProducts();
    }
  }

  // --- Invoice Operations with Real-Time Stock Sync ---
  Future<void> saveInvoice(Invoice invoice) async {
    final existingIndex = invoices.indexWhere((i) => i.id == invoice.id);
    final isNew = existingIndex == -1;

    // Calculate stock changes
    final Map<String, int> productDeltaMap = {};

    // 1. Revert previous stock change if editing an existing non-draft invoice
    if (!isNew) {
      final oldInvoice = invoices[existingIndex];
      if (!oldInvoice.isDraft) {
        for (final oldItem in oldInvoice.items) {
          final current = productDeltaMap[oldItem.productId] ?? 0;
          // Revert: if sale, add back (+); if purchase, subtract (-)
          final revert = oldInvoice.isSale ? oldItem.totalPieces : -oldItem.totalPieces;
          productDeltaMap[oldItem.productId] = current + revert;
        }
      }
    }

    // 2. Apply new stock change if not draft
    if (!invoice.isDraft) {
      for (final newItem in invoice.items) {
        final current = productDeltaMap[newItem.productId] ?? 0;
        // Apply: if sale, subtract (-); if purchase, add (+)
        final apply = invoice.isSale ? -newItem.totalPieces : newItem.totalPieces;
        productDeltaMap[newItem.productId] = current + apply;
      }
    }

    // 3. Update products in memory and persist
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final delta = productDeltaMap[p.id];
      if (delta != null && delta != 0) {
        final newStock = (p.stockPieces + delta).clamp(0, 999999999);
        products[i] = p.copyWith(
          stockPieces: newStock,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
    }
    await saveProducts();

    // 4. Upsert invoice
    if (isNew) {
      invoices.insert(0, invoice);
    } else {
      invoices[existingIndex] = invoice;
    }
    await saveInvoices();

    // 5. Automatically record treasury/payment if paid
    if (!invoice.isDraft && invoice.paidAmount > 0) {
      final tx = TreasuryTransaction(
        id: 'treasury-inv-${invoice.id}',
        type: invoice.isSale ? 'deposit' : 'expense',
        source: invoice.paymentAccount,
        amount: invoice.paidAmount,
        date: invoice.date,
        time: invoice.time,
        description: invoice.isSale
            ? 'دریافتی فاکتور فروش #${invoice.invoiceNumber} - ${invoice.customerName}'
            : 'پرداختی فاکتور خرید #${invoice.invoiceNumber} - ${invoice.customerName}',
        category: invoice.isSale ? 'فروش کالا' : 'خرید کالا (ورود به انبار)',
        referenceCode: 'INV-${invoice.id}',
        impactOnLiquidity: invoice.isSale ? 'inject' : 'deduct',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      treasury.removeWhere((t) => t.referenceCode == 'INV-${invoice.id}');
      treasury.insert(0, tx);
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final index = invoices.indexWhere((i) => i.id == invoiceId);
    if (index == -1) return;

    final target = invoices[index];

    // Restore stock if not draft
    if (!target.isDraft) {
      for (final item in target.items) {
        final pIndex = products.indexWhere((p) => p.id == item.productId);
        if (pIndex != -1) {
          final p = products[pIndex];
          final delta = target.isSale ? item.totalPieces : -item.totalPieces;
          products[pIndex] = p.copyWith(
            stockPieces: (p.stockPieces + delta).clamp(0, 999999999),
          );
        }
      }
      await saveProducts();
    }

    invoices.removeAt(index);
    treasury.removeWhere((t) => t.referenceCode == 'INV-$invoiceId');
    await saveInvoices();
  }

  // --- Customer Operations ---
  Future<void> addCustomer(Customer customer) async {
    customers.insert(0, customer);
    await saveCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer;
      await saveCustomers();
    }
  }

  // --- Initial Data Fallbacks ---
  List<Product> _initialProducts() => [
    Product(
      id: 'prod-1',
      name: 'آبنبات کپل کوچک توت فرنگی',
      category: 'آبنبات',
      purchasePrice: 4500,
      sellingPrice: 5800,
      coverPrice: 7000,
      piecesPerCarton: 800,
      packsPerCarton: 4,
      piecesPerPack: 200,
      stockPieces: 4000,
      unitTitle: 'عدد',
    ),
    Product(
      id: 'prod-2',
      name: 'آبنبات جرقه ای الهام',
      category: 'آبنبات',
      purchasePrice: 9000,
      sellingPrice: 10000,
      coverPrice: 12000,
      piecesPerCarton: 480,
      packsPerCarton: 4,
      piecesPerPack: 120,
      stockPieces: 2400,
      unitTitle: 'عدد',
    ),
    Product(
      id: 'prod-3',
      name: 'لواشک شلاقی ۶ برگی چیچک',
      category: 'لواشک',
      purchasePrice: 18000,
      sellingPrice: 22000,
      coverPrice: 25000,
      piecesPerCarton: 150,
      leavesPerPiece: 6,
      stockPieces: 750,
      unitTitle: 'عدد',
    ),
    Product(
      id: 'prod-4',
      name: 'بیسکویت پذیرایی کرمدار گرجی',
      category: 'بیسکویت',
      purchasePrice: 32000,
      sellingPrice: 38000,
      coverPrice: 45000,
      piecesPerCarton: 24,
      stockPieces: 240,
      unitTitle: 'بسته',
    ),
  ];

  List<Customer> _initialCustomers() => [
    Customer(
      id: 'cust-1',
      name: 'مدیریت انبار',
      company: 'دفتر مرکزی بازرگانی',
      customerType: 'supplier',
      phone: '09120000000',
      city: 'مرکزی',
      initialBalance: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    Customer(
      id: 'cust-2',
      name: 'صابر کریمی',
      company: 'بازرگانی کریمی',
      customerType: 'distributor',
      phone: '09123456789',
      city: 'تهران',
      initialBalance: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    Customer(
      id: 'cust-ali-partovi',
      name: 'علی پرتویی',
      company: 'بازرگانی پرتویی',
      customerType: 'both',
      phone: '09121112233',
      city: 'تهران',
      initialBalance: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ];
}
