import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
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

  List<Product> get filteredProducts {
    return storage.products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.code != null && p.code!.contains(_searchQuery)) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'همه' || p.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showQuickRestockDialog(Product product) {
    final cartonsController = TextEditingController();
    final extraPiecesController = TextEditingController();
    final purchasePriceController = TextEditingController(
      text: PersianFormatter.formatPrice(product.purchasePrice, includeUnit: false),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'شارژ سریع موجودی: ${product.name}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'موجودی فعلی: ${product.stockFormatted} (${PersianFormatter.toPersianDigits(product.stockPieces)} ${product.unitTitle})',
                  style: TextStyle(
                    fontSize: 12,
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
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final cartons = PersianFormatter.parseInt(cartonsController.text);
                      final extras = PersianFormatter.parseInt(extraPiecesController.text);
                      final totalNewPieces = (cartons * product.piecesPerCarton) + extras;

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
                    child: const Text('ثبت و شارژ انبار', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کالا از انبار'),
        content: Text('آیا از حذف کالای «${product.name}» اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              await storage.deleteProduct(product.id);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('انبارداری و موجودی کالا'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            tooltip: 'کالای جدید',
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
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'جستجوی نام کالا یا دسته‌بندی...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Categories Horizontal List
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = allCategories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // Product List
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.packageOpen, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        const SizedBox(height: 12),
                        Text(
                          'کالایی یافت نشد',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isLowStock = product.stockPieces <= 50;

                      return FlatCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Header Row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                    ),
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

                            // Packaging Spec
                            if (!product.isUnpackaged && product.piecesPerCarton > 1) ...[
                              Text(
                                'بسته‌بندی: هر کارتن ${PersianFormatter.toPersianDigits(product.piecesPerCarton)} عدد' +
                                    (product.packsPerCarton != null
                                        ? ' (${PersianFormatter.toPersianDigits(product.packsPerCarton)} بسته ${PersianFormatter.toPersianDigits(product.piecesPerPack ?? '')} تایی)'
                                        : ''),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],

                            // Stock Breakdown Box
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
                                          fontWeight: FontWeight.w700,
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

                            // Prices Row
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
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'قیمت خرید: ${PersianFormatter.formatPrice(product.purchasePrice)}' +
                                          (product.sellingPrice > 0
                                              ? ' (${PersianFormatter.toPersianDigits(product.profitMarginPercent.toStringAsFixed(0))}٪ سود)'
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

                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 6),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showQuickRestockDialog(product),
                                  icon: const Icon(LucideIcons.packagePlus, size: 14),
                                  label: const Text('شارژ سریع', style: TextStyle(fontSize: 12)),
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
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        label: const Text('کالای جدید', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
