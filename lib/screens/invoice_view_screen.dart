import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../widgets/flat_card.dart';
import '../widgets/custom_badge.dart';
import 'invoice_editor_screen.dart';

class InvoiceViewScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceViewScreen({super.key, required this.invoice});

  void _shareInvoiceText() {
    final buffer = StringBuffer();
    final isSale = invoice.isSale;
    buffer.writeln(isSale ? '🧾 فاکتور فروش کالا' : '📦 فاکتور خرید و ورود کالا');
    buffer.writeln('شماره فاکتور: #${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}');
    buffer.writeln('تاریخ: ${PersianFormatter.toPersianDigits(invoice.date)} - ساعت: ${PersianFormatter.toPersianDigits(invoice.time)}');
    buffer.writeln('طرف‌حساب: ${invoice.customerName}');
    if (invoice.customerPhone.isNotEmpty) buffer.writeln('تماس: ${invoice.customerPhone}');
    buffer.writeln('--------------------------------');

    for (int i = 0; i < invoice.items.length; i++) {
      final it = invoice.items[i];
      buffer.writeln(
        '${i + 1}. ${it.productName}: ' +
            PersianFormatter.formatStockBreakdown(it.totalPieces, it.piecesPerCarton, unitTitle: it.unitTitle) +
            ' | فی: ${PersianFormatter.formatPrice(isSale ? it.unitSellingPrice : it.unitPurchasePrice)} | جمع: ${PersianFormatter.formatPrice(it.totalPrice)}',
      );
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('جمع کل اقلام: ${PersianFormatter.formatPrice(invoice.subtotal)}');
    if (invoice.discount > 0) buffer.writeln('تخفیف: ${PersianFormatter.formatPrice(invoice.discount)}');
    if (invoice.tax > 0) buffer.writeln('مالیات: ${PersianFormatter.formatPrice(invoice.tax)}');
    buffer.writeln('مبلغ نهایی فاکتور: ${PersianFormatter.formatPrice(invoice.finalAmount)}');
    buffer.writeln('وضعیت: ${invoice.isDraft ? "پیش‌نویس" : (invoice.paymentStatus == "cash" ? "تسویه نقدی" : "نسیه / بدهی")}');

    Share.share(buffer.toString(), subject: 'فاکتور شماره ${invoice.invoiceNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = StorageService().settings;

    return Scaffold(
      appBar: AppBar(
        title: Text('فاکتور #${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: 'اشتراک‌گذاری فاکتور',
            onPressed: _shareInvoiceText,
          ),
          IconButton(
            icon: const Icon(LucideIcons.edit3),
            tooltip: 'ویرایش فاکتور',
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
              if (res == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Commercial Invoice Paper Container
          FlatCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bismillah
                Center(
                  child: Text(
                    settings.bismillah,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Brand & Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.brandName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.isSale ? 'فاکتور رسمی فروش کالا' : 'سند ورود کالا و خرید به انبار',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'شماره: #${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${PersianFormatter.toPersianDigits(invoice.date)} - ساعت ${PersianFormatter.toPersianDigits(invoice.time)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                // Customer Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDarkElevated : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.isSale ? 'خریدار / طرف‌حساب:' : 'فروشنده / تامین‌کننده:',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invoice.customerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      if (invoice.customerPhone.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('شماره تماس:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            const SizedBox(height: 2),
                            Text(invoice.customerPhone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 25, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 3, child: Text('شرح کالا', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 2, child: Text('تعداد / بسته', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 2, child: Text('قیمت واحد', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 2, child: Text('مبلغ کل', textAlign: TextAlign.left, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                    ],
                  ),
                ),

                // Items List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoice.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final it = invoice.items[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                if (invoice.showCoverPrice && it.coverPrice != null && it.coverPrice! > 0)
                                  Text(
                                    'جلد: ${PersianFormatter.formatPrice(it.coverPrice)}',
                                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatStockBreakdown(it.totalPieces, it.piecesPerCarton, unitTitle: it.unitTitle),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatPrice(invoice.isSale ? it.unitSellingPrice : it.unitPurchasePrice, includeUnit: false),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatPrice(it.totalPrice, includeUnit: false),
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                // Financial Totals Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('جمع کل اقلام:', style: TextStyle(fontSize: 12)),
                    Text(PersianFormatter.formatPrice(invoice.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (invoice.discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تخفیف:', style: TextStyle(fontSize: 12)),
                      Text('- ${PersianFormatter.formatPrice(invoice.discount)}', style: const TextStyle(fontSize: 13, color: AppColors.rose, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
                if (invoice.tax > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('مالیات و عوارض:', style: TextStyle(fontSize: 12)),
                      Text('+ ${PersianFormatter.formatPrice(invoice.tax)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDarkElevated : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('مبلغ نهایی قابل پرداخت:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      Text(
                        PersianFormatter.formatPrice(invoice.finalAmount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Status & Paid Amount Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('وضعیت سند: ', style: TextStyle(fontSize: 11)),
                        if (invoice.isDraft)
                          const CustomBadge(text: 'پیش‌نویس', textColor: AppColors.amber, backgroundColor: AppColors.amberSurface)
                        else if (invoice.paymentStatus == 'credit')
                          const CustomBadge(text: 'نسیه (بدهکار)', textColor: AppColors.rose, backgroundColor: AppColors.roseSurface)
                        else if (invoice.paymentStatus == 'partial')
                          const CustomBadge(text: 'پرداخت بخشی', textColor: AppColors.amber, backgroundColor: AppColors.amberSurface)
                        else
                          const CustomBadge(text: 'تسویه کامل نقدی', textColor: AppColors.emerald, backgroundColor: AppColors.emeraldSurface),
                      ],
                    ),
                    if (invoice.paidAmount > 0)
                      Text(
                        'پرداخت‌شده: ${PersianFormatter.formatPrice(invoice.paidAmount)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),

                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'یادداشت: ${invoice.notes}',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ],

                const SizedBox(height: 20),

                // Stamp & Signature Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text('مهر و امضای فروشنده', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        const SizedBox(height: 35),
                        Text(settings.sellerStampName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('امضای خریدار / تحویل‌گیرنده', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        const SizedBox(height: 35),
                        Text(invoice.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Action: Share or Edit
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareInvoiceText,
                  icon: const Icon(LucideIcons.share2, size: 16),
                  label: const Text('اشتراک‌گذاری خلاصه فاکتور'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
