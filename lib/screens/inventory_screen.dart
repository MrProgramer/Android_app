import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/persian_formatter.dart';
import '../widgets/flat_card.dart';
import '../widgets/custom_badge.dart';
import 'product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final StorageService storage = StorageService();

  String _searchQuery = '';
  String _selectedCategory = 'همه';
  String _salesStatusFilter = 'all'; // 'all', 'has_sales', 'top_sellers', 'no_sales'
  String _viewMode = 'catalog'; // 'catalog', 'analytics', 'audit'
  bool _isSecretMode = false;

  // Sales statistics calculation per product from invoices
  Map<String, ({int totalPieces, int totalCartons, double totalRevenue, double totalProfit})> get _salesStats {
    final map = <String, ({int totalPieces, int totalCartons, double totalRevenue, double totalProfit})>{};

    for (final inv in storage.invoices) {
      if (inv.isDraft || !inv.isSale) continue;
      for (final item in inv.items) {
        final current = map[item.productId] ?? (totalPieces: 0, totalCartons: 0, totalRevenue: 0.0, totalProfit: 0.0);
        final pieces = item.totalPieces;
        final ppc = item.piecesPerCarton > 0 ? item.piecesPerCarton : 1;
        final cartons = item.cartonsCount > 0 ? item.cartonsCount : pieces ~/ ppc;
        final rev = item.totalPrice;
        final profit = item.profitAmount;

        map[item.productId] = (
          totalPieces: current.totalPieces + pieces,
          totalCartons: current.totalCartons + cartons,
          totalRevenue: current.totalRevenue + rev,
          totalProfit: current.totalProfit + profit,
        );
      }
    }
    return map;
  }

  List<Product> get filteredProducts {
    final stats = _salesStats;

    return storage.products.where((p) {
      // 1. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchCat = p.category.toLowerCase().contains(q);
        final matchCode = p.code != null && p.code!.toLowerCase().contains(q);
        final matchBarcode = p.barcode != null && p.barcode!.contains(q);
        if (!matchName && !matchCat && !matchCode && !matchBarcode) return false;
      }

      // 2. Category Filter
      if (_selectedCategory != 'همه' && p.category != _selectedCategory) {
        return false;
      }

      // 3. Sales Status Filter
      final pStats = stats[p.id];
      final hasSales = pStats != null && pStats.totalPieces > 0;

      if (_salesStatusFilter == 'has_sales' && !hasSales) return false;
      if (_salesStatusFilter == 'no_sales' && hasSales) return false;
      if (_salesStatusFilter == 'top_sellers') {
        if (!hasSales || pStats.totalCartons < 5) return false;
      }

      return true;
    }).toList();
  }

  void _showQuickRestockDialog(Product product) {
    final cartonsController = TextEditingController();
    final extraPiecesController = TextEditingController();
    final purchasePriceController = TextEditingController(
      text: product.purchasePrice > 0 ? PersianFormatter.formatPrice(product.purchasePrice, includeUnit: false) : '',
    );
    String paymentSource = 'bank'; // 'bank', 'cash', 'none'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cartons = PersianFormatter.parseInt(cartonsController.text);
            final extras = PersianFormatter.parseInt(extraPiecesController.text);
            final totalNewPieces = (cartons * product.piecesPerCarton) + extras;
            final unitBuy = purchasePriceController.text.isNotEmpty
                ? PersianFormatter.parseDouble(purchasePriceController.text)
                : product.purchasePrice;
            final totalCost = totalNewPieces * unitBuy;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
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
                        Expanded(
                          child: Text(
                            'شارژ سریع موجودی: ${product.name}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'موجودی فعلی: ${product.stockFormatted} (${PersianFormatter.toPersianDigits(product.stockPieces)} ${product.unitTitle})',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (!product.isUnpackaged && product.piecesPerCarton > 1) ...[
                          Expanded(
                            child: TextFormField(
                              controller: cartonsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'تعداد کارتن',
                                hintText: 'مثلاً: ۵',
                                helperText: 'هر کارتن: ${PersianFormatter.toPersianDigits(product.piecesPerCarton)} عدد',
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TextFormField(
                            controller: extraPiecesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: product.isUnpackaged ? 'تعداد دانه / عدد' : 'دانه اضافه',
                              hintText: 'مثلاً: ۲۰',
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: purchasePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'قیمت خرید جدید (تومان) - اختیاری',
                        hintText: 'در صورت تغییر قیمت خرید',
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Source of payment
                    Row(
                      children: [
                        const Text('پرداخت از: ', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('بانک / کارت', style: TextStyle(fontSize: 10)),
                          selected: paymentSource == 'bank',
                          selectedColor: AppColors.primary,
                          onSelected: (_) => setSheetState(() => paymentSource = 'bank'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('صندوق نقدی', style: TextStyle(fontSize: 10)),
                          selected: paymentSource == 'cash',
                          selectedColor: AppColors.primary,
                          onSelected: (_) => setSheetState(() => paymentSource = 'cash'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('بدون پرداخت', style: TextStyle(fontSize: 10)),
                          selected: paymentSource == 'none',
                          selectedColor: AppColors.primary,
                          onSelected: (_) => setSheetState(() => paymentSource = 'none'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Cost Summary
                    if (totalNewPieces > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'افزایش: ${PersianFormatter.formatStockBreakdown(totalNewPieces, product.piecesPerCarton, unitTitle: product.unitTitle)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            ),
                            Text(
                              'ارزش بار: ${PersianFormatter.formatPrice(totalCost)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (totalNewPieces <= 0) return;

                          final newBuyPrice = purchasePriceController.text.isNotEmpty
                              ? PersianFormatter.parseDouble(purchasePriceController.text)
                              : null;

                          await storage.restockProduct(
                            product.id,
                            totalNewPieces,
                            newPurchasePrice: newBuyPrice,
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تعداد ${PersianFormatter.formatStockBreakdown(totalNewPieces, product.piecesPerCarton)} به انبار اضافه شد',
                                ),
                                backgroundColor: AppColors.emerald,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('ثبت و شارژ فوری انبار', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کالا از انبار', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text('آیا از حذف کالای «${product.name}» اطمینان دارید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              await storage.deleteProduct(product.id);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('کالای «${product.name}» حذف گردید'), backgroundColor: AppColors.rose),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
            child: const Text('حذف کالا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = ['همه', ...storage.categories];

    // Warehouse Valuation Metrics
    final totalWarehouseCostValue = storage.products.fold(0.0, (sum, p) => sum + (p.stockPieces * p.purchasePrice));
    final totalWarehouseSalesValue = storage.products.fold(0.0, (sum, p) => sum + (p.stockPieces * p.sellingPrice));
    final potentialProfit = totalWarehouseSalesValue - totalWarehouseCostValue;
    final totalCartons = storage.products.fold(0, (sum, p) => sum + p.cartons);
    final totalPieces = storage.products.fold(0, (sum, p) => sum + p.stockPieces);

    final lowStockCount = storage.products.where((p) {
      final c = p.piecesPerCarton > 0 ? p.stockPieces / p.piecesPerCarton : p.stockPieces.toDouble();
      return c <= 3;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت انبار و کاتالوگ کالاها'),
        actions: [
          // Secret Mode Toggle
          IconButton(
            icon: Icon(_isSecretMode ? LucideIcons.eyeOff : LucideIcons.eye),
            tooltip: _isSecretMode ? 'حالت محرمانه فعال است' : 'پنهان‌سازی قیمت خرید و سود',
            color: _isSecretMode ? AppColors.amber : null,
            onPressed: () => setState(() => _isSecretMode = !_isSecretMode),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            tooltip: 'افزودن کالای جدید',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              );
              if (res == true) setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. TOP WAREHOUSE CAPITAL & VALUATION SUMMARY
          // ==========================================
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderMetric(
                        'سرمایه خرید انبار',
                        PersianFormatter.formatSecretPrice(totalWarehouseCostValue, _isSecretMode),
                        AppColors.blue,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeaderMetric(
                        'ارزش فروش انبار',
                        PersianFormatter.formatPrice(totalWarehouseSalesValue),
                        AppColors.emerald,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeaderMetric(
                        'سود ناخالص بالقوه',
                        PersianFormatter.formatSecretPrice(potentialProfit, _isSecretMode),
                        AppColors.amber,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'موجودی فیزیکی: ${PersianFormatter.toPersianDigits(totalCartons)} کارتن (${PersianFormatter.toPersianDigits(totalPieces)} عدد/دانه)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                    if (lowStockCount > 0)
                      CustomBadge(
                        text: '${PersianFormatter.toPersianDigits(lowStockCount)} کالا رو به اتمام',
                        textColor: AppColors.amber,
                        backgroundColor: AppColors.amberSurface,
                        fontSize: 10,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. VIEW MODE SELECTOR (کاتالوگ / تحلیل / ممیزی)
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _buildViewModeTab('کاتالوگ کالاها', 'catalog', LucideIcons.package, isDark),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildViewModeTab('تحلیل انبار و ارزش', 'analytics', LucideIcons.trendingUp, isDark),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildViewModeTab('ممیزی و بازرسی', 'audit', LucideIcons.fileText, isDark),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. SEARCH & CATEGORY FILTERS (CATALOG MODE)
          // ==========================================
          if (_viewMode == 'catalog') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'جستجوی نام کالا، بارکد، یا کد...',
                  prefixIcon: const Icon(LucideIcons.search, size: 17),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 15),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            // Horizontal Category Pills
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: allCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = allCategories[index];
                  final isSelected = _selectedCategory == cat;
                  final count = cat == 'همه'
                      ? storage.products.length
                      : storage.products.where((p) => p.category == cat).length;

                  return FilterChip(
                    label: Text('$cat (${PersianFormatter.toPersianDigits(count)})'),
                    selected: isSelected,
                    selectedColor: AppColors.primarySurface,
                    backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    side: BorderSide(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                },
              ),
            ),

            // Sales Status Filters (همه | دارای فروش | پرفروش‌ترین‌ها | بدون فروش)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSalesStatusChip('همه کالاها', 'all', isDark),
                    _buildSalesStatusChip('دارای فروش در فاکتورها', 'has_sales', isDark),
                    _buildSalesStatusChip('پرفروش‌ترین‌ها (Top Sellers)', 'top_sellers', isDark),
                    _buildSalesStatusChip('بدون فروش (کالای خوابیده)', 'no_sales', isDark),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 4),

          // ==========================================
          // 4. MAIN BODY SWITCHER
          // ==========================================
          Expanded(
            child: _viewMode == 'analytics'
                ? _buildWarehouseAnalyticsView(isDark)
                : (_viewMode == 'audit'
                    ? _buildInventoryAuditView(isDark)
                    : _buildCatalogListView(isDark)),
          ),
        ],
      ),
      floatingActionButton: _viewMode == 'catalog'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                );
                if (res == true) setState(() {});
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('کالای جدید', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  // --- SUBVIEW 1: CATALOG LIST VIEW ---
  Widget _buildCatalogListView(bool isDark) {
    final list = filteredProducts;
    final stats = _salesStats;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageOpen, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            const SizedBox(height: 10),
            Text(
              'کالایی با این فیلتر در انبار یافت نشد',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = list[index];
        final pStats = stats[product.id];
        final isLowStock = product.cartons <= 3;
        final profitMargin = product.sellingPrice > 0
            ? ((product.sellingPrice - product.purchasePrice) / product.sellingPrice) * 100
            : 0.0;

        return FlatCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name and Category badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                          ),
                        ),
                        if (product.code != null && product.code!.isNotEmpty)
                          Text('کد کالا: ${product.code}', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      ],
                    ),
                  ),
                  CustomBadge(
                    text: product.category,
                    textColor: AppColors.primaryDark,
                    backgroundColor: AppColors.primarySurface,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Row 2: Packaging Spec
              if (!product.isUnpackaged && product.piecesPerCarton > 1) ...[
                Text(
                  'بسته‌بندی: هر کارتن ${PersianFormatter.toPersianDigits(product.piecesPerCarton)} عدد' +
                      (product.packsPerCarton != null
                          ? ' (${PersianFormatter.toPersianDigits(product.packsPerCarton)} بسته ${PersianFormatter.toPersianDigits(product.piecesPerPack ?? '')} تایی)'
                          : '') +
                      (product.leavesPerPiece != null ? ' - ${PersianFormatter.toPersianDigits(product.leavesPerPiece)} برگی' : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Row 3: Stock Breakdown Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                      : (isDark ? AppColors.cardDarkElevated : AppColors.bgLight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLowStock ? const Color(0xFFD97706) : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLowStock ? LucideIcons.alertTriangle : LucideIcons.boxes,
                          size: 15,
                          color: isLowStock ? const Color(0xFFD97706) : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'موجودی: ${product.stockFormatted}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isLowStock
                                ? const Color(0xFFD97706)
                                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'جمع: ${PersianFormatter.toPersianDigits(product.stockPieces)} ${product.unitTitle}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Row 4: Pricing Hierarchy
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قیمت فروش: ${PersianFormatter.formatPrice(product.sellingPrice)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'قیمت خرید: ${PersianFormatter.formatSecretPrice(product.purchasePrice, _isSecretMode)}' +
                            (!_isSecretMode && product.sellingPrice > 0
                                ? ' (${PersianFormatter.toPersianDigits(profitMargin.toStringAsFixed(0))}٪ سود)'
                                : ''),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  if (product.coverPrice != null && product.coverPrice! > 0)
                    CustomBadge(
                      text: 'جلد: ${PersianFormatter.formatPrice(product.coverPrice)}',
                      textColor: AppColors.blue,
                      backgroundColor: AppColors.blueSurface,
                    ),
                ],
              ),

              // Row 5: Sales performance banner if sold
              if (pStats != null && pStats.totalPieces > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'فروش در فاکتورها: ${PersianFormatter.toPersianDigits(pStats.totalCartons)} کارتن (${PersianFormatter.toPersianDigits(pStats.totalPieces)} عدد)',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald),
                      ),
                      Text(
                        'درآمد: ${PersianFormatter.formatAmountScale(pStats.totalRevenue)}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 4),

              // Row 6: Actions Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showQuickRestockDialog(product),
                    icon: const Icon(LucideIcons.packagePlus, size: 14),
                    label: const Text('شارژ سریع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(productToEdit: product),
                        ),
                      );
                      if (res == true) setState(() {});
                    },
                    icon: const Icon(LucideIcons.edit3, size: 14),
                    label: const Text('ویرایش', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 15, color: AppColors.rose),
                    onPressed: () => _confirmDelete(product),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SUBVIEW 2: WAREHOUSE ANALYTICS VIEW ---
  Widget _buildWarehouseAnalyticsView(bool isDark) {
    final catMap = <String, ({int count, int cartons, double costVal, double salesVal})>{};

    for (final p in storage.products) {
      final cat = p.category.isNotEmpty ? p.category : 'عمومی';
      final cur = catMap[cat] ?? (count: 0, cartons: 0, costVal: 0.0, salesVal: 0.0);
      catMap[cat] = (
        count: cur.count + 1,
        cartons: cur.cartons + p.cartons,
        costVal: cur.costVal + (p.stockPieces * p.purchasePrice),
        salesVal: cur.salesVal + (p.stockPieces * p.sellingPrice),
      );
    }

    final totalSalesVal = storage.products.fold(0.0, (sum, p) => sum + (p.stockPieces * p.sellingPrice));
    final sortedCats = catMap.entries.toList()..sort((a, b) => b.value.salesVal.compareTo(a.value.salesVal));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        FlatCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.trendingUp, size: 17, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('سهم ریالی دسته‌بندی‌ها از کل انبار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final entry = sortedCats[idx];
                  final pct = totalSalesVal > 0 ? (entry.value.salesVal / totalSalesVal) * 100 : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${entry.key} (${PersianFormatter.toPersianDigits(entry.value.count)} قلم • ${PersianFormatter.toPersianDigits(entry.value.cartons)} کارتن)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            PersianFormatter.formatPrice(entry.value.salesVal),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? AppColors.cardDarkElevated : AppColors.borderLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'سهم: ${PersianFormatter.toPersianDigits(pct.toStringAsFixed(1))}٪',
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUBVIEW 3: INVENTORY AUDIT VIEW ---
  Widget _buildInventoryAuditView(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: storage.products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final p = storage.products[idx];
        return FlatCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 25,
                child: Text(
                  PersianFormatter.toPersianDigits(idx + 1),
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                      'موجودی سیستم: ${p.stockFormatted}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${PersianFormatter.toPersianDigits(p.stockPieces)} ${p.unitTitle}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const CustomBadge(text: 'بررسی شده', textColor: AppColors.emerald, backgroundColor: AppColors.emeraldSurface, fontSize: 9),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderMetric(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeTab(String label, String mode, IconData icon, bool isDark) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesStatusChip(String title, String key, bool isDark) {
    final isSelected = _salesStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(title),
        selected: isSelected,
        selectedColor: AppColors.primarySurface,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        labelStyle: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? AppColors.primaryDark : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        ),
        side: BorderSide(color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        onSelected: (_) => setState(() => _salesStatusFilter = key),
      ),
    );
  }
}
