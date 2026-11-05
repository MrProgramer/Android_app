import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/settings.dart';
import '../../theme/app_colors.dart';
import '../../utils/persian_formatter.dart';
import '../../widgets/custom_badge.dart';

class MasterCommercialTemplate extends StatelessWidget {
  final Invoice invoice;
  final StoreSettings settings;
  final bool isDark;
  final bool showCoverPrice;
  final bool showProfit;
  final bool showStamp;
  final bool showBankDetails;
  final double fontScale;

  const MasterCommercialTemplate({
    super.key,
    required this.invoice,
    required this.settings,
    this.isDark = false,
    this.showCoverPrice = true,
    this.showProfit = false,
    this.showStamp = true,
    this.showBankDetails = true,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);
    final headerBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    final textMain = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16 * fontScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. INVOCATION
          Center(
            child: Text(
              settings.bismillah,
              style: TextStyle(
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.w700,
                color: textMuted,
              ),
            ),
          ),
          SizedBox(height: 8 * fontScale),

          // 2. OFFICIAL SER-BARG HEADER
          Container(
            padding: EdgeInsets.all(12 * fontScale),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Right Column: Store Brand & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.brandName,
                        style: TextStyle(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.w900,
                          color: textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3 * fontScale),
                      Text(
                        invoice.isSale ? 'فاکتور رسمی فروش کالا و خدمات' : 'سند رسمی ورود کالا و خرید به انبار',
                        style: TextStyle(
                          fontSize: 12 * fontScale,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Left Column: Metadata (Number, Date, Time)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('شماره فاکتور: ', style: TextStyle(fontSize: 11 * fontScale, color: textMuted)),
                        Text(
                          '#${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}',
                          style: TextStyle(fontSize: 14 * fontScale, fontWeight: FontWeight.w900, color: textMain),
                        ),
                      ],
                    ),
                    SizedBox(height: 3 * fontScale),
                    Text(
                      'تاریخ: ${PersianFormatter.toPersianDigits(invoice.date)} - ساعت ${PersianFormatter.toPersianDigits(invoice.time)}',
                      style: TextStyle(fontSize: 11 * fontScale, color: textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12 * fontScale),

          // 3. PARTIES INFORMATION BOX (BUYER & SELLER)
          Container(
            padding: EdgeInsets.all(10 * fontScale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Seller side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فروشنده: ${settings.brandName}',
                        style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain),
                      ),
                      if (settings.phone.isNotEmpty) ...[
                        SizedBox(height: 2 * fontScale),
                        Text('تلفن: ${PersianFormatter.toPersianDigits(settings.phone)}', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                      ],
                      if (settings.address.isNotEmpty) ...[
                        SizedBox(height: 2 * fontScale),
                        Text(settings.address, style: TextStyle(fontSize: 10 * fontScale, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                Container(width: 1, height: 45 * fontScale, color: borderColor),
                SizedBox(width: 10 * fontScale),
                // Buyer side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خریدار: ${invoice.customerName}',
                        style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain),
                      ),
                      if (invoice.customerPhone.isNotEmpty) ...[
                        SizedBox(height: 2 * fontScale),
                        Text('تلفن: ${PersianFormatter.toPersianDigits(invoice.customerPhone)}', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                      ],
                      if (invoice.customerCity.isNotEmpty) ...[
                        SizedBox(height: 2 * fontScale),
                        Text('شهر: ${invoice.customerCity}', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12 * fontScale),

          // 4. ITEMS TABLE
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table Header
                Container(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  padding: EdgeInsets.symmetric(horizontal: 8 * fontScale, vertical: 8 * fontScale),
                  child: Row(
                    children: [
                      SizedBox(width: 25 * fontScale, child: Text('#', style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: textMain))),
                      Expanded(flex: 4, child: Text('شرح کالا و خدمات', style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: textMain))),
                      Expanded(flex: 2, child: Text('تعداد / بسته', textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: textMain))),
                      Expanded(flex: 2, child: Text('قیمت واحد', textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: textMain))),
                      if (showCoverPrice)
                        Expanded(flex: 2, child: Text('روی جلد', textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: textMain))),
                      Expanded(flex: 2, child: Text('مبلغ کل (تومان)', textAlign: TextAlign.left, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: textMain))),
                    ],
                  ),
                ),
                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoice.items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, idx) {
                    final item = invoice.items[idx];
                    final isOdd = idx % 2 == 1;

                    return Container(
                      color: isOdd ? (isDark ? const Color(0xFF161F30) : const Color(0xFFF9FAFB)) : Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 8 * fontScale, vertical: 8 * fontScale),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 25 * fontScale,
                            child: Text(PersianFormatter.toPersianDigits(idx + 1), style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w700, color: textMain)),
                                if (item.category != null && item.category!.isNotEmpty)
                                  Text(item.category!, style: TextStyle(fontSize: 9 * fontScale, color: textMuted)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatStockBreakdown(item.totalPieces, item.piecesPerCarton, unitTitle: item.unitTitle),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w600, color: textMain),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatPrice(invoice.isSale ? item.unitSellingPrice : item.unitPurchasePrice, includeUnit: false),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10 * fontScale, color: textMain),
                            ),
                          ),
                          if (showCoverPrice)
                            Expanded(
                              flex: 2,
                              child: Text(
                                (item.coverPrice != null && item.coverPrice! > 0)
                                    ? PersianFormatter.formatPrice(item.coverPrice, includeUnit: false)
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10 * fontScale, color: AppColors.blue),
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatPrice(item.totalPrice, includeUnit: false),
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 12 * fontScale),

          // 5. FINANCIAL SUMMARY & WORDS
          Container(
            padding: EdgeInsets.all(12 * fontScale),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('جمع کل اقلام:', style: TextStyle(fontSize: 11 * fontScale, color: textMuted)),
                    Text(PersianFormatter.formatPrice(invoice.subtotal), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: textMain)),
                  ],
                ),
                if (invoice.discount > 0) ...[
                  SizedBox(height: 4 * fontScale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('تخفیف اعمال شده:', style: TextStyle(fontSize: 11 * fontScale, color: AppColors.rose)),
                      Text('- ${PersianFormatter.formatPrice(invoice.discount)}', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: AppColors.rose)),
                    ],
                  ),
                ],
                if (invoice.tax > 0) ...[
                  SizedBox(height: 4 * fontScale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('مالیات و عوارض:', style: TextStyle(fontSize: 11 * fontScale, color: textMuted)),
                      Text('+ ${PersianFormatter.formatPrice(invoice.tax)}', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: textMain)),
                    ],
                  ),
                ],
                Divider(height: 12 * fontScale, color: borderColor),
                // Final Amount Box
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('مبلغ نهایی فاکتور:', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.w900, color: textMain)),
                    Text(
                      PersianFormatter.formatPrice(invoice.finalAmount),
                      style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
                SizedBox(height: 4 * fontScale),
                // Verbal words
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'مبلغ به حروف: ${PersianFormatter.numberToPersianWords(invoice.finalAmount)}',
                    style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w600, color: textMuted),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10 * fontScale),

          // 6. PAYMENT STATUS & BANK DETAILS
          Container(
            padding: EdgeInsets.all(10 * fontScale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('وضعیت تسویه: ', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                          if (invoice.isDraft)
                            CustomBadge(text: 'پیش‌نویس فاکتور', textColor: AppColors.amber, backgroundColor: AppColors.amberSurface, fontSize: 9 * fontScale)
                          else if (invoice.paymentStatus == 'credit')
                            CustomBadge(text: 'نسیه (مانده بدهکار)', textColor: AppColors.rose, backgroundColor: AppColors.roseSurface, fontSize: 9 * fontScale)
                          else if (invoice.paymentStatus == 'partial')
                            CustomBadge(text: 'پرداخت بخشی', textColor: AppColors.amber, backgroundColor: AppColors.amberSurface, fontSize: 9 * fontScale)
                          else
                            CustomBadge(text: 'تسویه نقدی کامل', textColor: AppColors.emerald, backgroundColor: AppColors.emeraldSurface, fontSize: 9 * fontScale),
                        ],
                      ),
                      if (invoice.paidAmount > 0) ...[
                        SizedBox(height: 3 * fontScale),
                        Text('مبلغ پرداخت شده: ${PersianFormatter.formatPrice(invoice.paidAmount)}', style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w700, color: textMain)),
                      ],
                    ],
                  ),
                ),
                if (showBankDetails && settings.cardNumber.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('شماره کارت واریز (${settings.bankName}):', style: TextStyle(fontSize: 9 * fontScale, color: textMuted)),
                        SizedBox(height: 2 * fontScale),
                        Text(
                          PersianFormatter.toPersianDigits(settings.cardNumber),
                          style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            SizedBox(height: 8 * fontScale),
            Text(
              'توضیحات: ${invoice.notes}',
              style: TextStyle(fontSize: 10 * fontScale, color: textMuted),
            ),
          ],

          SizedBox(height: 18 * fontScale),

          // 7. OFFICIAL SEALS AND SIGNATURES
          if (showStamp)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('مهر و امضای فروشنده', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                    SizedBox(height: 28 * fontScale),
                    Text(settings.sellerStampName, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain)),
                  ],
                ),
                Column(
                  children: [
                    Text('امضای تحویل‌گیرنده / خریدار', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                    SizedBox(height: 28 * fontScale),
                    Text(invoice.customerName, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
