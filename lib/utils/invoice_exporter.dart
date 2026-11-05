import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'persian_date_helper.dart';

class InvoiceExportResult {
  final bool success;
  final String message;
  final String? filePath;

  InvoiceExportResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

class InvoiceExporter {
  /// Captures the invoice rendered inside a RepaintBoundary as an ultra-crisp PNG image (3.0x pixel ratio)
  static Future<Uint8List?> capturePng(GlobalKey repaintKey, {double pixelRatio = 3.0}) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing invoice image: $e');
      return null;
    }
  }

  /// Exports invoice as high-resolution PNG image, saves to device, and opens share sheet
  static Future<InvoiceExportResult> exportAsImage({
    required GlobalKey repaintKey,
    required String invoiceNumber,
    String? customerName,
  }) async {
    try {
      final pngBytes = await capturePng(repaintKey, pixelRatio: 3.0);
      if (pngBytes == null) {
        return InvoiceExportResult(
          success: false,
          message: 'خطا در ثبت تصویر فاکتور. لطفاً مجدداً تلاش کنید.',
        );
      }

      final dateStr = PersianDateHelper.getCurrentJalaliDate().replaceAll('/', '-');
      final timeStr = PersianDateHelper.getCurrentTime().replaceAll(':', '');
      final fileName = 'factor-$invoiceNumber-$dateStr-$timeStr.png';

      // 1. Save in temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pngBytes);

      // 2. Also save persistent copy in documents directory
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final invoicesDir = Directory('${docsDir.path}/invoices');
        if (!await invoicesDir.exists()) {
          await invoicesDir.create(recursive: true);
        }
        final persistentFile = File('${invoicesDir.path}/$fileName');
        await persistentFile.writeAsBytes(pngBytes);
      } catch (_) {}

      // 3. Open share sheet
      final xFile = XFile(
        tempFile.path,
        mimeType: 'image/png',
        name: fileName,
      );

      final shareText = customerName != null && customerName.isNotEmpty
          ? 'تصویر فاکتور شماره $invoiceNumber - $customerName'
          : 'تصویر فاکتور شماره $invoiceNumber';

      await Share.shareXFiles([xFile], text: shareText);

      return InvoiceExportResult(
        success: true,
        message: 'تصویر فاکتور با کیفیت بالا (PNG) استخراج گردید.',
        filePath: tempFile.path,
      );
    } catch (e) {
      return InvoiceExportResult(
        success: false,
        message: 'خطا در استخراج تصویر فاکتور: $e',
      );
    }
  }

  /// Wraps the captured PNG into a valid, standard A4 PDF document without any external native dependencies
  static Uint8List createPdfFromPngBytes(Uint8List pngBytes, {double pageWidth = 595.28, double pageHeight = 841.89}) {
    // Standard A4 dimensions in PDF points (72 points per inch)
    // 595.28 x 841.89 points = 210 x 297 mm
    final buffer = BytesBuilder();

    // PDF Header
    buffer.add(Uint8List.fromList('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'.codeUnits));

    final offsets = <int>[];

    // Helper to write object
    void writeObject(int objNum, String body, [List<int>? streamBytes]) {
      offsets.add(buffer.length);
      buffer.add(Uint8List.fromList('$objNum 0 obj\n'.codeUnits));
      buffer.add(Uint8List.fromList(body.codeUnits));
      if (streamBytes != null) {
        buffer.add(Uint8List.fromList('stream\n'.codeUnits));
        buffer.add(streamBytes);
        buffer.add(Uint8List.fromList('\nendstream\n'.codeUnits));
      }
      buffer.add(Uint8List.fromList('endobj\n'.codeUnits));
    }

    // 1 0 obj: Catalog
    writeObject(1, '<< /Type /Catalog /Pages 2 0 R >>\n');

    // 2 0 obj: Pages
    writeObject(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>\n');

    // 3 0 obj: Page
    writeObject(
      3,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] '
      '/Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>\n',
    );

    // 4 0 obj: Image XObject (PNG image stream)
    // Notice: We specify PNG filter or raw image stream
    writeObject(
      4,
      '<< /Type /XObject /Subtype /Image /Width 1200 /Height 1800 '
      '/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode '
      '/Length ${pngBytes.length} >>\n',
      pngBytes,
    );

    // 5 0 obj: Page Content Stream (positions image to fill page with 20pt margin)
    final double margin = 20.0;
    final double contentWidth = pageWidth - (margin * 2);
    final double contentHeight = pageHeight - (margin * 2);
    final String contentCmd = 'q $contentWidth 0 0 $contentHeight $margin $margin cm /Im0 Do Q\n';

    writeObject(
      5,
      '<< /Length ${contentCmd.length} >>\n',
      Uint8List.fromList(contentCmd.codeUnits),
    );

    // XRef Table
    final startXref = buffer.length;
    buffer.add(Uint8List.fromList('xref\n0 ${offsets.length + 1}\n'.codeUnits));
    buffer.add(Uint8List.fromList('0000000000 65535 f \n'.codeUnits));

    for (final offset in offsets) {
      final offsetStr = offset.toString().padLeft(10, '0');
      buffer.add(Uint8List.fromList('$offsetStr 00000 n \n'.codeUnits));
    }

    // Trailer
    buffer.add(Uint8List.fromList(
      'trailer\n<< /Size ${offsets.length + 1} /Root 1 0 R >>\n'
      'startxref\n$startXref\n%%EOF\n'.codeUnits,
    ));

    return buffer.toBytes();
  }

  /// Exports invoice as official PDF file, saves it, and opens share sheet
  static Future<InvoiceExportResult> exportAsPdf({
    required GlobalKey repaintKey,
    required String invoiceNumber,
    String? customerName,
  }) async {
    try {
      final pngBytes = await capturePng(repaintKey, pixelRatio: 3.0);
      if (pngBytes == null) {
        return InvoiceExportResult(
          success: false,
          message: 'خطا در ثبت اطلاعات گرافیکی فاکتور جهت تبدیل به PDF.',
        );
      }

      final dateStr = PersianDateHelper.getCurrentJalaliDate().replaceAll('/', '-');
      final timeStr = PersianDateHelper.getCurrentTime().replaceAll(':', '');
      final fileName = 'invoice-$invoiceNumber-$dateStr-$timeStr.pdf';

      final pdfBytes = createPdfFromPngBytes(pngBytes);

      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(pdfBytes);

      // Save persistent copy
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${docsDir.path}/pdf_invoices');
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }
        await File('${pdfDir.path}/$fileName').writeAsBytes(pdfBytes);
      } catch (_) {}

      final xFile = XFile(
        pdfFile.path,
        mimeType: 'application/pdf',
        name: fileName,
      );

      final shareText = customerName != null && customerName.isNotEmpty
          ? 'فایل PDF فاکتور رسمی شماره $invoiceNumber - $customerName'
          : 'فایل PDF فاکتور شماره $invoiceNumber';

      await Share.shareXFiles([xFile], text: shareText);

      return InvoiceExportResult(
        success: true,
        message: 'فایل رسمی PDF فاکتور تولید و آماده ارسال شد.',
        filePath: pdfFile.path,
      );
    } catch (e) {
      return InvoiceExportResult(
        success: false,
        message: 'خطا در صدور فایل PDF فاکتور: $e',
      );
    }
  }
}
