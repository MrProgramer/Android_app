import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/settings.dart';
import '../../theme/app_colors.dart';
import '../../utils/persian_formatter.dart';
import '../../widgets/custom_badge.dart';

class FintechModernTemplate extends StatelessWidget {
  final Invoice invoice;
  final StoreSettings settings;
  final bool isDark;
  final bool showCoverPrice;
  final bool showStamp;
  final double fontScale;

  const FintechModernTemplate({
    super.key,
    required this.invoice,
    required this.settings,
    this.isDark = false,
    this.showCoverPrice = true,
    this.showStamp = true,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(18 * fontScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. FINTECH HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * fontScale, vertical: 4 * fontScale),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      invoice.isSale ? 'فاکتور فروش' : 'فاکتور خرید',
                      style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 6 * fontScale),
                  Text(
                    settings.brandName,
                    style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.w900, color: textMain),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}',
                    style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  SizedBox(height: 3 * fontScale),
                  Text(
                    PersianFormatter.toPersianDigits(invoice.date),
                    style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w600, color: textMuted),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 14 * fontScale),

          // 2. CLIENT MINI-CARD
          Container(
            padding: EdgeInsets.all(12 * fontScale),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طرف‌حساب:', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                    SizedBox(height: 2 * fontScale),
                    Text(
                      invoice.customerName,
                      style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.w800, color: textMain),
                    ),
                  ],
                ),
                if (invoice.customerPhone.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('تماس:', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                      SizedBox(height: 2 * fontScale),
                      Text(
                        PersianFormatter.toPersianDigits(invoice.customerPhone),
                        style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w600, color: textMain),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          SizedBox(height: 14 * fontScale),

          // 3. MODERN ITEMS TABLE
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: AppColors.primarySurface,
                  padding: EdgeInsets.symmetric(horizontal: 10 * fontScale, vertical: 8 * fontScale),
                  child: Row(
                    children: [
                      SizedBox(width: 25 * fontScale, child: Text('#', style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 4, child: Text('کالا', style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 2, child: Text('مقدار', textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 2, child: Text('فی واحد', textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                      Expanded(flex: 2, child: Text('مبلغ کل', textAlign: TextAlign.left, style: TextStyle(fontSize: 10 * fontScale, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoice.items.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, idx) {
                    final item = invoice.items[idx];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10 * fontScale, vertical: 8 * fontScale),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 25 * fontScale,
                            child: Text(PersianFormatter.toPersianDigits(idx + 1), style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(item.productName, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w700, color: textMain)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              PersianFormatter.formatStockBreakdown(item.totalPieces, item.piecesPerCarton, unitTitle: item.unitTitle),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10 * fontScale, color: textMain),
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

          SizedBox(height: 14 * fontScale),

          // 4. BIG TOTAL HERO CARD
          Container(
            padding: EdgeInsets.all(14 * fontScale),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مبلغ کل قابل پرداخت:', style: TextStyle(fontSize: 11 * fontScale, color: Colors.white70)),
                    SizedBox(height: 3 * fontScale),
                    Text(
                      PersianFormatter.formatPrice(invoice.finalAmount),
                      style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * fontScale, vertical: 5 * fontScale),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoice.isDraft ? 'پیش‌نویس' : (invoice.paymentStatus == 'cash' ? 'تسویه نقدی' : 'نسیه'),
                    style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12 * fontScale),

          // Bank Details if set
          if (settings.cardNumber.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10 * fontScale),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('شماره کارت (${settings.bankName}):', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                  Text(
                    PersianFormatter.toPersianDigits(settings.cardNumber),
                    style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w800, color: textMain, letterSpacing: 1),
                  ),
                ],
              ),
            ),

          if (showStamp) ...[
            SizedBox(height: 16 * fontScale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تایید و مهر مدیریت: ${settings.sellerStampName}', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                Text('تحویل‌گیرنده: ${invoice.customerName}', style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
