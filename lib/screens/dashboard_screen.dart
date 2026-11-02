import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../utils/persian_date_helper.dart';
import '../widgets/flat_card.dart';
import '../widgets/stat_kpi_card.dart';
import '../widgets/custom_badge.dart';
import 'invoice_editor_screen.dart';
import 'invoice_view_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToInventory;
  final VoidCallback onNavigateToInvoices;

  const DashboardScreen({
    super.key,
    required this.onNavigateToInventory,
    required this.onNavigateToInvoices,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService storage = StorageService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate Financial KPIs
    final salesInvoices = storage.invoices.where((i) => !i.isDraft && i.isSale).toList();
    final purchaseInvoices = storage.invoices.where((i) => !i.isDraft && i.isPurchase).toList();
    final draftInvoices = storage.invoices.where((i) => i.isDraft).toList();

    final totalSalesAmount = salesInvoices.fold(0.0, (sum, i) => sum + i.finalAmount);
    final totalPurchasesAmount = purchaseInvoices.fold(0.0, (sum, i) => sum + i.finalAmount);
    final totalProfit = salesInvoices.fold(0.0, (sum, i) => sum + i.totalProfit);

    // Calculate Stock Valuation
    final totalStockValue = storage.products.fold(0.0, (sum, p) => sum + (p.stockPieces * p.purchasePrice));
    final totalStockPieces = storage.products.fold(0, (sum, p) => sum + p.stockPieces);
    final lowStockProducts = storage.products.where((p) => p.stockPieces <= 50).toList();

    // Latest 5 invoices
    final recentInvoices = storage.invoices.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await storage.loadAll();
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              FlatCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storage.settings.brandName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PersianDateHelper.getReadableJalaliDate(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.wifiOff, size: 13, color: AppColors.primaryDark),
                              SizedBox(width: 5),
                              Text(
                                'کاملاً آفلاین',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InvoiceEditorScreen(isPurchase: false),
                                ),
                              );
                              setState(() {});
                            },
                            icon: const Icon(LucideIcons.plusCircle, size: 16),
                            label: const Text('فاکتور فروش'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InvoiceEditorScreen(isPurchase: true),
                                ),
                              );
                              setState(() {});
                            },
                            icon: const Icon(LucideIcons.arrowDownLeft, size: 16),
                            label: const Text('خرید / ورود بار'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                              side: BorderSide(
                                color: isDark ? AppColors.borderDarkStrong : AppColors.borderLightStrong,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  StatKpiCard(
                    title: 'فروش کل',
                    value: PersianFormatter.formatPrice(totalSalesAmount),
                    subtitle: '${PersianFormatter.toPersianDigits(salesInvoices.length)} فاکتور صادر شده',
                    icon: LucideIcons.trendingUp,
                    iconColor: AppColors.emerald,
                    iconBgColor: AppColors.emeraldSurface,
                  ),
                  StatKpiCard(
                    title: 'سود ناخالص فروش',
                    value: PersianFormatter.formatPrice(totalProfit),
                    subtitle: totalSalesAmount > 0
                        ? 'حاشیه سود: ${PersianFormatter.toPersianDigits(((totalProfit / totalSalesAmount) * 100).toStringAsFixed(1))}٪'
                        : 'بدون فروش',
                    icon: LucideIcons.coins,
                    iconColor: AppColors.amber,
                    iconBgColor: AppColors.amberSurface,
                  ),
                  StatKpiCard(
                    title: 'ارزش موجودی انبار',
                    value: PersianFormatter.formatPrice(totalStockValue),
                    subtitle: '${PersianFormatter.toPersianDigits(totalStockPieces)} عدد کالا',
                    icon: LucideIcons.package,
                    iconColor: AppColors.blue,
                    iconBgColor: AppColors.blueSurface,
                    onTap: widget.onNavigateToInventory,
                  ),
                  StatKpiCard(
                    title: 'خرید و ورودی بار',
                    value: PersianFormatter.formatPrice(totalPurchasesAmount),
                    subtitle: '${PersianFormatter.toPersianDigits(purchaseInvoices.length)} فاکتور خرید',
                    icon: LucideIcons.shoppingBag,
                    iconColor: AppColors.rose,
                    iconBgColor: AppColors.roseSurface,
                  ),
                ],
              ),

              // Low Stock Warning if exists
              if (lowStockProducts.isNotEmpty) ...[
                const SizedBox(height: 16),
                FlatCard(
                  backgroundColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                  borderColor: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                  padding: const EdgeInsets.all(12),
                  onTap: widget.onNavigateToInventory,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${PersianFormatter.toPersianDigits(lowStockProducts.length)} کالا در انبار رو به اتمام است! جهت بررسی کلیک کنید.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.chevronLeft, size: 16, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Recent Invoices Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آخرین فاکتورهای ثبت‌شده',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onNavigateToInvoices,
                    icon: const Text('مشاهده همه', style: TextStyle(fontSize: 12)),
                    label: const Icon(LucideIcons.arrowLeft, size: 14),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (recentInvoices.isEmpty)
                FlatCard(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.fileText, size: 36, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        const SizedBox(height: 10),
                        Text(
                          'هنوز هیچ فاکتوری ثبت نشده است',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentInvoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final inv = recentInvoices[index];
                    return FlatCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceViewScreen(invoice: inv),
                          ),
                        );
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: inv.isSale
                                  ? (inv.isDraft ? AppColors.amberSurface : AppColors.emeraldSurface)
                                  : AppColors.blueSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              inv.isSale ? LucideIcons.fileText : LucideIcons.packagePlus,
                              size: 18,
                              color: inv.isSale
                                  ? (inv.isDraft ? AppColors.amber : AppColors.emerald)
                                  : AppColors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '#${PersianFormatter.toPersianDigits(inv.invoiceNumber)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      inv.customerName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${PersianFormatter.toPersianDigits(inv.date)} - ${PersianFormatter.toPersianDigits(inv.time)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•  ${PersianFormatter.toPersianDigits(inv.items.length)} قلم',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                PersianFormatter.formatPrice(inv.finalAmount),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (inv.isDraft)
                                const CustomBadge(
                                  text: 'پیش‌نویس',
                                  textColor: AppColors.amber,
                                  backgroundColor: AppColors.amberSurface,
                                )
                              else if (inv.paymentStatus == 'credit')
                                const CustomBadge(
                                  text: 'نسیه',
                                  textColor: AppColors.rose,
                                  backgroundColor: AppColors.roseSurface,
                                )
                              else
                                const CustomBadge(
                                  text: 'نقدی',
                                  textColor: AppColors.emerald,
                                  backgroundColor: AppColors.emeraldSurface,
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
