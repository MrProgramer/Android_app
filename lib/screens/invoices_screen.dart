import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../widgets/flat_card.dart';
import '../widgets/custom_badge.dart';
import 'invoice_editor_screen.dart';
import 'invoice_view_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> with SingleTickerProviderStateMixin {
  final StorageService storage = StorageService();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Invoice> getFilteredInvoices(int tabIndex) {
    List<Invoice> base;
    switch (tabIndex) {
      case 1: // Sales only (non-draft)
        base = storage.invoices.where((i) => !i.isDraft && i.isSale).toList();
        break;
      case 2: // Purchases only (non-draft)
        base = storage.invoices.where((i) => !i.isDraft && i.isPurchase).toList();
        break;
      case 3: // Drafts
        base = storage.invoices.where((i) => i.isDraft).toList();
        break;
      default: // All
        base = storage.invoices;
    }

    if (_searchQuery.isEmpty) return base;

    return base.where((i) {
      return i.invoiceNumber.contains(_searchQuery) ||
          i.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.date.contains(_searchQuery) ||
          i.items.any((item) => item.productName.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  void _confirmDelete(Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف فاکتور'),
        content: Text(
          'آیا از حذف فاکتور #${PersianFormatter.toPersianDigits(invoice.invoiceNumber)} (${invoice.customerName}) اطمینان دارید؟\n' +
              (invoice.isDraft ? '' : 'موجودی کالاهای فاکتور به انبار بازگردانده خواهد شد.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              await storage.deleteInvoice(invoice.id);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white),
            child: const Text('حذف فاکتور'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('فهرست و آرشیو فاکتورها'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filePlus2),
            tooltip: 'فاکتور فروش جدید',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceEditorScreen(isPurchase: false)),
              );
              if (res == true) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.packagePlus),
            tooltip: 'فاکتور خرید جدید',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceEditorScreen(isPurchase: true)),
              );
              if (res == true) setState(() {});
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            onTap: (_) => setState(() {}),
            tabs: [
              Tab(text: 'همه (${PersianFormatter.toPersianDigits(storage.invoices.length)})'),
              Tab(text: 'فروش (${PersianFormatter.toPersianDigits(storage.invoices.where((i) => !i.isDraft && i.isSale).length)})'),
              Tab(text: 'خرید (${PersianFormatter.toPersianDigits(storage.invoices.where((i) => !i.isDraft && i.isPurchase).length)})'),
              Tab(text: 'پیش‌نویس (${PersianFormatter.toPersianDigits(storage.invoices.where((i) => i.isDraft).length)})'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'جستجوی شماره فاکتور، نام خریدار، یا کالای داخل فاکتور...',
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

          // Invoices List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIndex) {
                final list = getFilteredInvoices(tabIndex);

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileX, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        const SizedBox(height: 12),
                        Text(
                          'فاکتوری در این بخش یافت نشد',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invoice = list[index];

                    return FlatCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceViewScreen(invoice: invoice),
                          ),
                        );
                        setState(() {});
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: invoice.isSale
                                      ? (invoice.isDraft ? AppColors.amberSurface : AppColors.emeraldSurface)
                                      : AppColors.blueSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  invoice.isSale ? LucideIcons.fileText : LucideIcons.arrowDownLeft,
                                  size: 16,
                                  color: invoice.isSale
                                      ? (invoice.isDraft ? AppColors.amber : AppColors.emerald)
                                      : AppColors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'فاکتور #${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  invoice.customerName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                  ),
                                ),
                              ),
                              if (invoice.isDraft)
                                const CustomBadge(
                                  text: 'پیش‌نویس',
                                  textColor: AppColors.amber,
                                  backgroundColor: AppColors.amberSurface,
                                )
                              else if (invoice.paymentStatus == 'credit')
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
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${PersianFormatter.toPersianDigits(invoice.date)} ساعت ${PersianFormatter.toPersianDigits(invoice.time)} • ${PersianFormatter.toPersianDigits(invoice.items.length)} قلم کالا',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              Text(
                                PersianFormatter.formatPrice(invoice.finalAmount),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InvoiceViewScreen(invoice: invoice),
                                    ),
                                  );
                                  setState(() {});
                                },
                                icon: const Icon(LucideIcons.eye, size: 14),
                                label: const Text('مشاهده و چاپ', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InvoiceEditorScreen(
                                        invoiceToEdit: invoice,
                                        isPurchase: invoice.isPurchase,
                                      ),
                                    ),
                                  );
                                  if (res == true) setState(() {});
                                },
                                icon: const Icon(LucideIcons.edit3, size: 14),
                                label: const Text('ویرایش', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 15, color: AppColors.rose),
                                onPressed: () => _confirmDelete(invoice),
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
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvoiceEditorScreen(isPurchase: false)),
          );
          if (res == true) setState(() {});
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('فاکتور جدید', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
