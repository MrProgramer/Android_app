import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';
import '../services/calculation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
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

  TimePeriodFilter _selectedPeriod = TimePeriodFilter.month;
  String _executiveSection = 'all'; // 'all', 'performance', 'volume', 'debtors', 'liquidity'
  bool _isSecretMode = false;

  // Monthly Sales Target (Default: 50,000,000 Tomans)
  double _monthlyTarget = 50000000;

  // Table search & filter
  String _tableSearchQuery = '';
  String _tableFilterType = 'all'; // 'all', 'sale', 'purchase', 'credit', 'cash'

  void _editMonthlyTarget() {
    final controller = TextEditingController(
      text: PersianFormatter.formatPrice(_monthlyTarget, includeUnit: false),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنظیم هدف فروش ماهانه', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مبلغ هدف فروش ماهانه را به تومان وارد فرمایید:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'هدف فروش (تومان)',
                suffixText: 'تومان',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTarget = PersianFormatter.parseDouble(controller.text);
              if (newTarget > 0) {
                setState(() => _monthlyTarget = newTarget);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('ثبت هدف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayStr = PersianDateHelper.getCurrentJalaliDate();

    // 1. Filter Invoices by selected time period
    final periodInvoices = storage.invoices.where((inv) {
      return PersianFormatter.isDateInPeriod(inv.date, _selectedPeriod, todayStr: todayStr);
    }).toList();

    final finalInvoices = periodInvoices.where((i) => !i.isDraft).toList();
    final salesInvoices = finalInvoices.where((i) => i.isSale).toList();
    final purchaseInvoices = finalInvoices.where((i) => i.isPurchase).toList();

    // 2. Financial Metrics
    final totalSalesRevenue = salesInvoices.fold(0.0, (sum, i) => sum + i.finalAmount);
    final totalSalesCost = salesInvoices.fold(0.0, (sum, i) => sum + i.items.fold(0.0, (s, it) => s + it.totalPurchaseCost));
    final totalProfit = totalSalesRevenue - totalSalesCost;
    final averageMargin = totalSalesRevenue > 0 ? (totalProfit / totalSalesRevenue) * 100 : 0.0;

    final cashSales = salesInvoices.where((i) => i.paymentStatus == 'cash');
    final creditSales = salesInvoices.where((i) => i.paymentStatus == 'credit' || i.paymentStatus == 'partial');
    final cashAmount = cashSales.fold(0.0, (sum, i) => sum + i.finalAmount);
    final creditAmount = creditSales.fold(0.0, (sum, i) => sum + CalculationService.getInvoiceCreditDebtAmount(i));
    final cashPercent = totalSalesRevenue > 0 ? ((cashAmount / totalSalesRevenue) * 100).round() : 100;

    // 3. Purchase Metrics
    final totalPurchasesAmount = purchaseInvoices.fold(0.0, (sum, i) => sum + i.finalAmount);

    // 4. Warehouse & Stock Valuation Metrics
    final totalWarehouseCostValue = storage.products.fold(0.0, (sum, p) => sum + (p.stockPieces * p.purchasePrice));
    final totalWarehouseSalesValue = storage.products.fold(0.0, (sum, p) => sum + (p.stockPieces * p.sellingPrice));
    final totalStockPieces = storage.products.fold(0, (sum, p) => sum + p.stockPieces);
    final totalStockCartons = storage.products.fold(0, (sum, p) => sum + p.cartons);

    // 5. Volume Intelligence (Cartons Sold vs Purchased)
    final totalCartonsSold = salesInvoices.fold(0, (sum, inv) {
      return sum + inv.items.fold(0, (s, it) => s + it.cartonsCount);
    });
    final totalCartonsPurchased = purchaseInvoices.fold(0, (sum, inv) {
      return sum + inv.items.fold(0, (s, it) => s + it.cartonsCount);
    });
    final totalVolumeAvailable = totalStockCartons + totalCartonsSold;
    final cartonSellThrough = totalVolumeAvailable > 0 ? ((totalCartonsSold / totalVolumeAvailable) * 100).clamp(0, 100).round() : 0;

    // 6. Market Receivables & Supplier Payables
    final totalReceivables = CalculationService.calculateTotalCustomerReceivables(
      storage.customers,
      storage.invoices,
      storage.payments,
      storage.productReturns,
    );
    final totalSupplierPayables = CalculationService.calculateTotalSupplierPayables(storage.invoices);
    final netMarketPosition = totalReceivables - totalSupplierPayables;

    // 7. Real-Time Liquidity (Cash + Bank)
    final liquidityData = CalculationService.calculateRealTimeLiquidity(
      storage.payments,
      storage.treasury,
      storage.invoices,
    );

    // 8. Low Stock & Dead Stock & Top Debtors
    final lowStockProducts = storage.products.where((p) {
      final c = p.piecesPerCarton > 0 ? p.stockPieces / p.piecesPerCarton : p.stockPieces.toDouble();
      return c <= 3;
    }).toList();

    final deadStockProducts = CalculationService.getDeadStockProducts(storage.products, salesInvoices);
    final topDebtors = CalculationService.getTopDebtors(
      storage.customers,
      storage.invoices,
      storage.payments,
      storage.productReturns,
    );

    // 9. Monthly Target Progress
    final targetPercent = _monthlyTarget > 0 ? ((totalSalesRevenue / _monthlyTarget) * 100).clamp(0.0, 100.0) : 0.0;
    final targetGap = (_monthlyTarget - totalSalesRevenue).clamp(0.0, double.infinity);

    // 10. Dashboard Invoices Table List
    final filteredTableInvoices = finalInvoices.where((inv) {
      if (_tableFilterType == 'sale' && !inv.isSale) return false;
      if (_tableFilterType == 'purchase' && !inv.isPurchase) return false;
      if (_tableFilterType == 'credit' && inv.paymentStatus == 'cash') return false;
      if (_tableFilterType == 'cash' && inv.paymentStatus != 'cash') return false;

      if (_tableSearchQuery.trim().isNotEmpty) {
        final q = _tableSearchQuery.trim().toLowerCase();
        final matchNum = inv.invoiceNumber.toLowerCase().contains(q);
        final matchCust = inv.customerName.toLowerCase().contains(q);
        final matchItem = inv.items.any((it) => it.productName.toLowerCase().contains(q));
        return matchNum || matchCust || matchItem;
      }
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await storage.loadAll();
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // ==========================================
              // 1. EXECUTIVE TOP HEADER
              // ==========================================
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
                              storage.settings.bismillah,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              storage.settings.brandName,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              PersianDateHelper.getReadableJalaliDate(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Secret Mode Toggle
                            IconButton(
                              onPressed: () {
                                setState(() => _isSecretMode = !_isSecretMode);
                              },
                              icon: Icon(
                                _isSecretMode ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 20,
                                color: _isSecretMode ? AppColors.amber : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                              tooltip: _isSecretMode ? 'حالت محرمانه فعال است' : 'فعال‌سازی حالت محرمانه (پنهان‌سازی سود و خرید)',
                            ),
                            // Offline Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.wifiOff, size: 12, color: AppColors.primaryDark),
                                  SizedBox(width: 5),
                                  Text(
                                    'آفلاین',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InvoiceEditorScreen(isPurchase: false),
                                ),
                              );
                              if (res == true) setState(() {});
                            },
                            icon: const Icon(LucideIcons.plusCircle, size: 16),
                            label: const Text('فاکتور فروش جدید', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InvoiceEditorScreen(isPurchase: true),
                                ),
                              );
                              if (res == true) setState(() {});
                            },
                            icon: const Icon(LucideIcons.arrowDownLeft, size: 16, color: AppColors.blue),
                            label: const Text('ورود کالا به انبار', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                              side: BorderSide(
                                color: isDark ? AppColors.borderDarkStrong : AppColors.borderLightStrong,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 2. TIME PERIOD FILTER BAR
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TimePeriodFilter.values.map((period) {
                    final isSelected = _selectedPeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(period.labelFa),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedPeriod = period);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 3. MONTHLY SALES TARGET PROGRESS
              // ==========================================
              FlatCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(LucideIcons.trendingUp, size: 15, color: AppColors.emerald),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'هدف فروش ماهانه',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.edit2, size: 13),
                              onPressed: _editMonthlyTarget,
                              tooltip: 'تغییر هدف فروش',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        CustomBadge(
                          text: '${PersianFormatter.toPersianDigits(targetPercent.toStringAsFixed(0))}٪ محقق شده',
                          textColor: AppColors.emerald,
                          backgroundColor: AppColors.emeraldSurface,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: (targetPercent / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.cardDarkElevated : AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'محقق شده: ${PersianFormatter.formatPrice(totalSalesRevenue)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                          ),
                        ),
                        Text(
                          targetGap > 0
                              ? 'مانده تا هدف: ${PersianFormatter.formatPrice(targetGap)}'
                              : 'هدف به طور کامل محقق شد!',
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

              const SizedBox(height: 14),

              // ==========================================
              // 4. PRIMARY KPI FINANCIAL GRID (۶ کارت کلیدی)
              // ==========================================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  // 1. Total Sales
                  StatKpiCard(
                    title: 'فروش کل دوره',
                    value: PersianFormatter.formatPrice(totalSalesRevenue),
                    subtitle: 'نقد: ${PersianFormatter.toPersianDigits(cashPercent)}٪ • نسیه: ${PersianFormatter.toPersianDigits(100 - cashPercent)}٪',
                    badgeText: '${PersianFormatter.toPersianDigits(salesInvoices.length)} فاکتور',
                    badgeColor: AppColors.emerald,
                    icon: LucideIcons.trendingUp,
                    iconColor: AppColors.emerald,
                    iconBgColor: AppColors.emeraldSurface,
                    onTap: widget.onNavigateToInvoices,
                  ),

                  // 2. Gross Profit
                  StatKpiCard(
                    title: 'سود ناخالص فروش',
                    value: PersianFormatter.formatSecretPrice(totalProfit, _isSecretMode),
                    subtitle: _isSecretMode ? 'حالت محرمانه' : 'حاشیه سود: ${PersianFormatter.toPersianDigits(averageMargin.toStringAsFixed(1))}٪',
                    badgeText: _isSecretMode ? '***' : PersianFormatter.formatAmountScale(totalProfit),
                    badgeColor: AppColors.amber,
                    icon: LucideIcons.coins,
                    iconColor: AppColors.amber,
                    iconBgColor: AppColors.amberSurface,
                  ),

                  // 3. Warehouse Valuation
                  StatKpiCard(
                    title: 'ارزش سرمایه انبار',
                    value: PersianFormatter.formatSecretPrice(totalWarehouseCostValue, _isSecretMode),
                    subtitle: 'ارزش فروش: ${PersianFormatter.formatPrice(totalWarehouseSalesValue)}',
                    badgeText: '${PersianFormatter.toPersianDigits(totalStockCartons)} کارتن',
                    badgeColor: AppColors.blue,
                    icon: LucideIcons.package,
                    iconColor: AppColors.blue,
                    iconBgColor: AppColors.blueSurface,
                    onTap: widget.onNavigateToInventory,
                  ),

                  // 4. Market Receivables
                  StatKpiCard(
                    title: 'مطالبات نسیه بازار',
                    value: PersianFormatter.formatPrice(totalReceivables),
                    subtitle: 'تراز خالص بازار: ${PersianFormatter.formatAmountScale(netMarketPosition)}',
                    badgeText: '${PersianFormatter.toPersianDigits(topDebtors.length)} بدهکار',
                    badgeColor: AppColors.rose,
                    icon: LucideIcons.users,
                    iconColor: AppColors.rose,
                    iconBgColor: AppColors.roseSurface,
                  ),

                  // 5. Purchases & Inward Goods
                  StatKpiCard(
                    title: 'خرید و ورود بار',
                    value: PersianFormatter.formatPrice(totalPurchasesAmount),
                    subtitle: '${PersianFormatter.toPersianDigits(purchaseInvoices.length)} فاکتور خرید در این دوره',
                    badgeText: '${PersianFormatter.toPersianDigits(totalCartonsPurchased)} کارتن',
                    badgeColor: AppColors.cyan,
                    icon: LucideIcons.shoppingBag,
                    iconColor: AppColors.cyan,
                    iconBgColor: AppColors.cyanSurface,
                  ),

                  // 6. Live Liquidity (Cash + Bank)
                  StatKpiCard(
                    title: 'نقدینگی در دسترس',
                    value: PersianFormatter.formatPrice(liquidityData.totalLiquidity),
                    subtitle: 'بانک: ${PersianFormatter.formatAmountScale(liquidityData.bankBalance)} • نقد: ${PersianFormatter.formatAmountScale(liquidityData.cashBalance)}',
                    badgeText: 'لحظه‌ای',
                    badgeColor: AppColors.primary,
                    icon: LucideIcons.wallet,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primarySurface,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==========================================
              // 5. EXECUTIVE PERSPECTIVE TABS
              // ==========================================
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSectionChip('همه (جامع)', 'all', isDark),
                    _buildSectionChip('هوش کارتن و انبار', 'volume', isDark),
                    _buildSectionChip('رادار مطالبات بازار', 'debtors', isDark),
                    _buildSectionChip('کالاهای راکد و کسری', 'risk', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 6. VOLUME INTELLIGENCE SECTION
              // ==========================================
              if (_executiveSection == 'all' || _executiveSection == 'volume') ...[
                FlatCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.boxes, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('هوش حجم و گردش کارتن انبار', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          CustomBadge(
                            text: 'نرخ گردش: ${PersianFormatter.toPersianDigits(cartonSellThrough)}٪',
                            textColor: AppColors.primaryDark,
                            backgroundColor: AppColors.primarySurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricMiniBox(
                              'کارتن فروش‌رفته',
                              '${PersianFormatter.toPersianDigits(totalCartonsSold)} کارتن',
                              AppColors.emerald,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricMiniBox(
                              'کارتن ورودی بار',
                              '${PersianFormatter.toPersianDigits(totalCartonsPurchased)} کارتن',
                              AppColors.blue,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricMiniBox(
                              'موجودی کارتن',
                              '${PersianFormatter.toPersianDigits(totalStockCartons)} کارتن',
                              AppColors.amber,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // 7. TOP DEBTORS RISK RADAR
              // ==========================================
              if (_executiveSection == 'all' || _executiveSection == 'debtors') ...[
                FlatCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.users, size: 16, color: AppColors.rose),
                              SizedBox(width: 8),
                              Text('رادار ریسک بدهکاران بازار', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          Text(
                            'جمع: ${PersianFormatter.formatAmountScale(totalReceivables)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.rose),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (topDebtors.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: Text('هیچ مانده بدهکاری در بازار ثبت نشده است', style: TextStyle(fontSize: 12))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topDebtors.length,
                          separatorBuilder: (_, __) => const Divider(height: 14),
                          itemBuilder: (context, idx) {
                            final debtor = topDebtors[idx];
                            final isHigh = debtor.riskLevel == 'high';

                            return Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (isHigh ? AppColors.rose : AppColors.amber).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    PersianFormatter.toPersianDigits(idx + 1),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isHigh ? AppColors.rose : AppColors.amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        debtor.customer.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      if (debtor.lastDate.isNotEmpty)
                                        Text(
                                          'آخرین خرید: ${PersianFormatter.toPersianDigits(debtor.lastDate)}',
                                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      PersianFormatter.formatPrice(debtor.liveBalance),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: isHigh ? AppColors.rose : AppColors.amber,
                                      ),
                                    ),
                                    CustomBadge(
                                      text: isHigh ? 'ریسک بالا' : 'ریسک متوسط',
                                      textColor: isHigh ? AppColors.rose : AppColors.amber,
                                      backgroundColor: isHigh ? AppColors.roseSurface : AppColors.amberSurface,
                                      fontSize: 9,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // 8. DEAD STOCK RADAR (کالاهای خوابیده انبار)
              // ==========================================
              if ((_executiveSection == 'all' || _executiveSection == 'risk') && deadStockProducts.isNotEmpty) ...[
                FlatCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.packageOpen, size: 16, color: AppColors.amber),
                              SizedBox(width: 8),
                              Text('کالاهای راکد انبار (خواب سرمایه)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          CustomBadge(
                            text: '${PersianFormatter.toPersianDigits(deadStockProducts.length)} قلم راکد',
                            textColor: AppColors.amber,
                            backgroundColor: AppColors.amberSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deadStockProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, idx) {
                          final item = deadStockProducts[idx];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'موجودی: ${item.product.stockFormatted}',
                                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'خواب سرمایه: ${PersianFormatter.formatAmountScale(item.tiedUpCapital)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.amber),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ==========================================
              // 9. LOW STOCK WARNING STRIP
              // ==========================================
              if (lowStockProducts.isNotEmpty) ...[
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
                          '${PersianFormatter.toPersianDigits(lowStockProducts.length)} کالا در انبار رو به اتمام است (کمتر از ۳ کارتن).',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.chevronLeft, size: 16, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ==========================================
              // 10. RECENT INVOICES LEDGER WITH SEARCH & FILTER
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'دفتر فاکتورهای اخیر (${PersianFormatter.toPersianDigits(filteredTableInvoices.length)})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onNavigateToInvoices,
                    icon: const Text('مشاهده کامل', style: TextStyle(fontSize: 12)),
                    label: const Icon(LucideIcons.arrowLeft, size: 14),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Search & Filter Box for Dashboard Invoices
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'جستجوی شماره، مشتری یا کالا...',
                        prefixIcon: const Icon(LucideIcons.search, size: 16),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        suffixIcon: _tableSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 14),
                                onPressed: () => setState(() => _tableSearchQuery = ''),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _tableSearchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filter Type Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tableFilterType,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textMainDark : AppColors.textMainLight),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('همه')),
                          DropdownMenuItem(value: 'sale', child: Text('فروش')),
                          DropdownMenuItem(value: 'purchase', child: Text('خرید')),
                          DropdownMenuItem(value: 'credit', child: Text('نسیه')),
                          DropdownMenuItem(value: 'cash', child: Text('نقدی')),
                        ],
                        onChanged: (v) => setState(() => _tableFilterType = v ?? 'all'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (filteredTableInvoices.isEmpty)
                FlatCard(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.fileX, size: 36, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        const SizedBox(height: 8),
                        Text('فاکتوری در این فیلتر یافت نشد', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTableInvoices.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final inv = filteredTableInvoices[index];
                    return FlatCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InvoiceViewScreen(invoice: inv)),
                        );
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: inv.isSale
                                  ? (inv.isDraft ? AppColors.amberSurface : AppColors.emeraldSurface)
                                  : AppColors.blueSurface,
                              borderRadius: BorderRadius.circular(9),
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
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        inv.customerName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${PersianFormatter.toPersianDigits(inv.date)} - ${PersianFormatter.toPersianDigits(inv.time)} • ${PersianFormatter.toPersianDigits(inv.items.length)} قلم',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
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
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (inv.isDraft)
                                const CustomBadge(text: 'پیش‌نویس', textColor: AppColors.amber, backgroundColor: AppColors.amberSurface)
                              else if (inv.paymentStatus == 'credit')
                                const CustomBadge(text: 'نسیه', textColor: AppColors.rose, backgroundColor: AppColors.roseSurface)
                              else
                                const CustomBadge(text: 'نقدی', textColor: AppColors.emerald, backgroundColor: AppColors.emeraldSurface),
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

  Widget _buildSectionChip(String title, String key, bool isDark) {
    final isSelected = _executiveSection == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(title),
        selected: isSelected,
        selectedColor: AppColors.primarySurface,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryDark : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        onSelected: (_) => setState(() => _executiveSection = key),
      ),
    );
  }

  Widget _buildMetricMiniBox(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
