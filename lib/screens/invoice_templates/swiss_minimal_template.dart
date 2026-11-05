import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/settings.dart';
import '../../theme/app_colors.dart';
import '../../utils/persian_formatter.dart';

class SwissMinimalTemplate extends StatelessWidget {
  final Invoice invoice;
  final StoreSettings settings;
  final bool isDark;
  final bool showCoverPrice;
  final bool showStamp;
  final double fontScale;

  const SwissMinimalTemplate({
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
    final bgColor = isDark ? const Color(0xFF0B0F19) : Colors.white;
    final textMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final hairLine = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      color: bgColor,
      padding: EdgeInsets.all(20 * fontScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Minimal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.brandName.toUpperCase(),
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: textMain,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'INVOICE #${invoice.invoiceNumber}',
                    style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w800, color: textMain),
                  ),
                  Text(
                    PersianFormatter.toPersianDigits(invoice.date),
                    style: TextStyle(fontSize: 10 * fontScale, color: textMuted),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16 * fontScale),
          Container(height: 1, color: hairLine),
          SizedBox(height: 16 * fontScale),

          // Customer metadata line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('صورتحساب برای:', style: TextStyle(fontSize: 9 * fontScale, color: textMuted)),
                  SizedBox(height: 2 * fontScale),
                  Text(invoice.customerName, style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.w800, color: textMain)),
                ],
              ),
              if (invoice.customerPhone.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('شماره تماس:', style: TextStyle(fontSize: 9 * fontScale, color: textMuted)),
                    SizedBox(height: 2 * fontScale),
                    Text(PersianFormatter.toPersianDigits(invoice.customerPhone), style: TextStyle(fontSize: 11 * fontScale, color: textMain)),
                  ],
                ),
            ],
          ),

          SizedBox(height: 20 * fontScale),

          // Items minimalist table
          ...invoice.items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8 * fontScale),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(PersianFormatter.toPersianDigits(idx + 1), style: TextStyle(fontSize: 10 * fontScale, color: textMuted)),
                      SizedBox(width: 8 * fontScale),
                      Expanded(
                        child: Text(item.productName, style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: textMain)),
                      ),
                      Text(
                        PersianFormatter.formatPrice(item.totalPrice, includeUnit: false),
                        style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w800, color: textMain),
                      ),
                    ],
                  ),
                  SizedBox(height: 2 * fontScale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        PersianFormatter.formatStockBreakdown(item.totalPieces, item.piecesPerCarton, unitTitle: item.unitTitle),
                        style: TextStyle(fontSize: 10 * fontScale, color: textMuted),
                      ),
                      Text(
                        'فی: ${PersianFormatter.formatPrice(invoice.isSale ? item.unitSellingPrice : item.unitPurchasePrice, includeUnit: false)} تومان',
                        style: TextStyle(fontSize: 10 * fontScale, color: textMuted),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * fontScale),
                  Container(height: 0.5, color: hairLine),
                ],
              ),
            );
          }),

          SizedBox(height: 16 * fontScale),

          // Total line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('جمع قابل پرداخت', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: textMuted)),
              Text(
                PersianFormatter.formatPrice(invoice.finalAmount),
                style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),

          if (showStamp) ...[
            SizedBox(height: 30 * fontScale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(settings.sellerStampName, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain)),
                Text(invoice.customerName, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.w800, color: textMain)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
