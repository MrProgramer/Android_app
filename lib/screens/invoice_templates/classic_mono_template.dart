import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/settings.dart';
import '../../utils/persian_formatter.dart';

class ClassicMonoTemplate extends StatelessWidget {
  final Invoice invoice;
  final StoreSettings settings;
  final bool showCoverPrice;
  final bool showStamp;
  final double fontScale;

  const ClassicMonoTemplate({
    super.key,
    required this.invoice,
    required this.settings,
    this.showCoverPrice = true,
    this.showStamp = true,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    const black = Colors.black;
    const grey = Color(0xFF4B5563);
    final border = Border.all(color: black, width: 1.2);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(14 * fontScale),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: black, width: 2.0),
        ),
        padding: EdgeInsets.all(12 * fontScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bismillah
            Center(
              child: Text(
                settings.bismillah,
                style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: black),
              ),
            ),
            SizedBox(height: 6 * fontScale),

            // Ser-barg
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.brandName,
                      style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.w900, color: black),
                    ),
                    Text(
                      invoice.isSale ? 'صورتحساب فروش کالا' : 'صورتحساب ورود کالا (خرید)',
                      style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: black),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(8 * fontScale),
                  decoration: BoxDecoration(border: border),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('شماره: ${PersianFormatter.toPersianDigits(invoice.invoiceNumber)}', style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: black)),
                      Text('تاریخ: ${PersianFormatter.toPersianDigits(invoice.date)}', style: TextStyle(fontSize: 11 * fontScale, color: black)),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 10 * fontScale),

            // Parties Grid Box
            Container(
              decoration: BoxDecoration(border: border),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFE5E7EB),
                    padding: EdgeInsets.all(4 * fontScale),
                    child: Center(
                      child: Text('مشخصات طرفین معامله', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: black)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8 * fontScale),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('فروشنده: ${settings.brandName}', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: black)),
                              Text('تلفن: ${PersianFormatter.toPersianDigits(settings.phone)}', style: TextStyle(fontSize: 10 * fontScale, color: grey)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 35 * fontScale, color: black),
                        SizedBox(width: 8 * fontScale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('خریدار: ${invoice.customerName}', style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: black)),
                              Text('تلفن: ${PersianFormatter.toPersianDigits(invoice.customerPhone)}', style: TextStyle(fontSize: 10 * fontScale, color: grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10 * fontScale),

            // Items Table
            Table(
              border: TableBorder.all(color: black, width: 1.0),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(4),
                2: FlexColumnWidth(2.5),
                3: FlexColumnWidth(2.5),
                4: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
                  children: [
                    _buildTableCell('#', true, fontScale),
                    _buildTableCell('شرح کالا', true, fontScale),
                    _buildTableCell('تعداد/کارتن', true, fontScale),
                    _buildTableCell('فی (تومان)', true, fontScale),
                    _buildTableCell('جمع کل (تومان)', true, fontScale),
                  ],
                ),
                ...invoice.items.asMap().entries.map((e) {
                  final idx = e.key;
                  final it = e.value;
                  return TableRow(
                    children: [
                      _buildTableCell(PersianFormatter.toPersianDigits(idx + 1), false, fontScale),
                      _buildTableCell(it.productName, false, fontScale, align: TextAlign.right),
                      _buildTableCell(PersianFormatter.formatStockBreakdown(it.totalPieces, it.piecesPerCarton, unitTitle: it.unitTitle), false, fontScale),
                      _buildTableCell(PersianFormatter.formatPrice(invoice.isSale ? it.unitSellingPrice : it.unitPurchasePrice, includeUnit: false), false, fontScale),
                      _buildTableCell(PersianFormatter.formatPrice(it.totalPrice, includeUnit: false), false, fontScale),
                    ],
                  );
                }),
              ],
            ),

            SizedBox(height: 10 * fontScale),

            // Financial Summary Block
            Container(
              decoration: BoxDecoration(border: border),
              padding: EdgeInsets.all(8 * fontScale),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('مبلغ کل اقلام:', style: TextStyle(fontSize: 11 * fontScale, color: black)),
                      Text(PersianFormatter.formatPrice(invoice.subtotal), style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.bold, color: black)),
                    ],
                  ),
                  if (invoice.discount > 0) ...[
                    SizedBox(height: 3 * fontScale),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('تخفیف:', style: TextStyle(fontSize: 11 * fontScale, color: black)),
                        Text('- ${PersianFormatter.formatPrice(invoice.discount)}', style: TextStyle(fontSize: 12 * fontScale, color: black)),
                      ],
                    ),
                  ],
                  Divider(height: 8 * fontScale, color: black),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('مبلغ نهایی قابل پرداخت:', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.w900, color: black)),
                      Text(PersianFormatter.formatPrice(invoice.finalAmount), style: TextStyle(fontSize: 15 * fontScale, fontWeight: FontWeight.w900, color: black)),
                    ],
                  ),
                  SizedBox(height: 4 * fontScale),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('به حروف: ${PersianFormatter.numberToPersianWords(invoice.finalAmount)}', style: TextStyle(fontSize: 10 * fontScale, color: grey)),
                  ),
                ],
              ),
            ),

            if (showStamp) ...[
              SizedBox(height: 24 * fontScale),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مهر و امضای فروشنده\n\n${settings.sellerStampName}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: black)),
                  Text('امضای تحویل‌گیرنده\n\n${invoice.customerName}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11 * fontScale, fontWeight: FontWeight.bold, color: black)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, bool isHeader, double fontScale, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * fontScale, vertical: 6 * fontScale),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: (isHeader ? 10 : 10) * fontScale,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
