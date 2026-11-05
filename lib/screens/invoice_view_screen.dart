import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/persian_formatter.dart';
import '../utils/invoice_exporter.dart';
import '../widgets/flat_card.dart';
import '../widgets/custom_badge.dart';
import 'invoice_editor_screen.dart';
import 'invoice_templates/master_commercial_template.dart';
import 'invoice_templates/fintech_modern_template.dart';
import 'invoice_templates/classic_mono_template.dart';
import 'invoice_templates/swiss_minimal_template.dart';

enum InvoiceDesignTemplate {
  masterCommercial,
  fintechModern,
  classicMono,
  swissMinimal;

  String get labelFa {
    switch (this) {
      case InvoiceDesignTemplate.masterCommercial:
        return 'رسمی بازرگانی';
      case InvoiceDesignTemplate.fintechModern:
        return 'مدرن فین‌تک';
      case InvoiceDesignTemplate.classicMono:
        return 'تک‌رنگ چاپ';
      case InvoiceDesignTemplate.swissMinimal:
        return 'مینیمال سوئیسی';
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceDesignTemplate.masterCommercial:
        return LucideIcons.fileText;
      case InvoiceDesignTemplate.fintechModern:
        return LucideIcons.trendingUp;
      case InvoiceDesignTemplate.classicMono:
        return LucideIcons.printer;
      case InvoiceDesignTemplate.swissMinimal:
        return LucideIcons.layoutDashboard;
    }
  }
}

class InvoiceViewScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceViewScreen({super.key, required this.invoice});

  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  final GlobalKey _invoiceRepaintKey = GlobalKey();
  final StorageService storage = StorageService();

  InvoiceDesignTemplate _selectedTemplate = InvoiceDesignTemplate.masterCommercial;
  bool _showCoverPrice = true;
  bool _showStamp = true;
  bool _showBankDetails = true;
  bool _isTemplateDark = false;
  double _fontScale = 1.0;
  bool _isExporting = false;

  late Invoice _currentInvoice;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
    _showCoverPrice = _currentInvoice.showCoverPrice;
  }

  void _shareInvoiceText() {
    final buffer = StringBuffer();
    final isSale = _currentInvoice.isSale;
    buffer.writeln(isSale ? '🧾 صورتحساب رسمی فروش کالا' : '📦 سند ورود کالا و خرید به انبار');
    buffer.writeln('فروشگاه: ${storage.settings.brandName}');
    buffer.writeln('شماره فاکتور: #${PersianFormatter.toPersianDigits(_currentInvoice.invoiceNumber)}');
    buffer.writeln('تاریخ: ${PersianFormatter.toPersianDigits(_currentInvoice.date)} ساعت ${PersianFormatter.toPersianDigits(_currentInvoice.time)}');
    buffer.writeln('طرف‌حساب: ${_currentInvoice.customerName}');
    if (_currentInvoice.customerPhone.isNotEmpty) buffer.writeln('تماس: ${_currentInvoice.customerPhone}');
    buffer.writeln('================================');

    for (int i = 0; i < _currentInvoice.items.length; i++) {
      final it = _currentInvoice.items[i];
      buffer.writeln(
        '${i + 1}. ${it.productName}\n' +
            '   مقدار: ${PersianFormatter.formatStockBreakdown(it.totalPieces, it.piecesPerCarton, unitTitle: it.unitTitle)}\n' +
            '   فی: ${PersianFormatter.formatPrice(isSale ? it.unitSellingPrice : it.unitPurchasePrice)} | جمع: ${PersianFormatter.formatPrice(it.totalPrice)}',
      );
    }

    buffer.writeln('================================');
    buffer.writeln('جمع کل اقلام: ${PersianFormatter.formatPrice(_currentInvoice.subtotal)}');
    if (_currentInvoice.discount > 0) buffer.writeln('تخفیف: ${PersianFormatter.formatPrice(_currentInvoice.discount)}');
    if (_currentInvoice.tax > 0) buffer.writeln('مالیات: ${PersianFormatter.formatPrice(_currentInvoice.tax)}');
    buffer.writeln('مبلغ نهایی فاکتور: ${PersianFormatter.formatPrice(_currentInvoice.finalAmount)}');
    buffer.writeln('مبلغ به حروف: ${PersianFormatter.numberToPersianWords(_currentInvoice.finalAmount)}');
    buffer.writeln('وضعیت تسویه: ${_currentInvoice.isDraft ? "پیش‌نویس" : (_currentInvoice.paymentStatus == "cash" ? "تسویه نقدی" : "نسیه")}');
    if (storage.settings.cardNumber.isNotEmpty) {
      buffer.writeln('شماره کارت (${storage.settings.bankName}): ${PersianFormatter.toPersianDigits(storage.settings.cardNumber)}');
    }

    Share.share(buffer.toString(), subject: 'فاکتور شماره ${_currentInvoice.invoiceNumber}');
  }

  void _exportAsImage() async {
    setState(() => _isExporting = true);
    final res = await InvoiceExporter.exportAsImage(
      repaintKey: _invoiceRepaintKey,
      invoiceNumber: _currentInvoice.invoiceNumber,
      customerName: _currentInvoice.customerName,
    );
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
        ),
      );
    }
  }

  void _exportAsPdf() async {
    setState(() => _isExporting = true);
    final res = await InvoiceExporter.exportAsPdf(
      repaintKey: _invoiceRepaintKey,
      invoiceNumber: _currentInvoice.invoiceNumber,
      customerName: _currentInvoice.customerName,
    );
    setState(() => _isExporting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppColors.emerald : AppColors.rose,
        ),
      );
    }
  }

  void _showTemplateOptionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'شخصی‌سازی و تنظیمات نمایش فاکتور',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Density Scale
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تراکم و مقیاس فونت:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('متراکم', style: TextStyle(fontSize: 10)),
                            selected: _fontScale == 0.88,
                            onSelected: (_) {
                              setState(() => _fontScale = 0.88);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('استاندارد', style: TextStyle(fontSize: 10)),
                            selected: _fontScale == 1.0,
                            onSelected: (_) {
                              setState(() => _fontScale = 1.0);
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('درشت', style: TextStyle(fontSize: 10)),
                            selected: _fontScale == 1.15,
                            onSelected: (_) {
                              setState(() => _fontScale = 1.15);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  SwitchListTile(
                    title: const Text('نمایش ستون قیمت روی جلد (مصرف‌کننده)', style: TextStyle(fontSize: 12)),
                    value: _showCoverPrice,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      setState(() => _showCoverPrice = v);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('نمایش مهر و امضای رسمی در پایین فاکتور', style: TextStyle(fontSize: 12)),
                    value: _showStamp,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      setState(() => _showStamp = v);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('نمایش مشخصات حساب و شماره کارت بانکی', style: TextStyle(fontSize: 12)),
                    value: _showBankDetails,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      setState(() => _showBankDetails = v);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('پیش‌نمایش در حالت شب (Dark Canvas)', style: TextStyle(fontSize: 12)),
                    value: _isTemplateDark,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      setState(() => _isTemplateDark = v);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveTemplate() {
    switch (_selectedTemplate) {
      case InvoiceDesignTemplate.masterCommercial:
        return MasterCommercialTemplate(
          invoice: _currentInvoice,
          settings: storage.settings,
          isDark: _isTemplateDark,
          showCoverPrice: _showCoverPrice,
          showStamp: _showStamp,
          showBankDetails: _showBankDetails,
          fontScale: _fontScale,
        );
      case InvoiceDesignTemplate.fintechModern:
        return FintechModernTemplate(
          invoice: _currentInvoice,
          settings: storage.settings,
          isDark: _isTemplateDark,
          showCoverPrice: _showCoverPrice,
          showStamp: _showStamp,
          fontScale: _fontScale,
        );
      case InvoiceDesignTemplate.classicMono:
        return ClassicMonoTemplate(
          invoice: _currentInvoice,
          settings: storage.settings,
          showCoverPrice: _showCoverPrice,
          showStamp: _showStamp,
          fontScale: _fontScale,
        );
      case InvoiceDesignTemplate.swissMinimal:
        return SwissMinimalTemplate(
          invoice: _currentInvoice,
          settings: storage.settings,
          isDark: _isTemplateDark,
          showCoverPrice: _showCoverPrice,
          showStamp: _showStamp,
          fontScale: _fontScale,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('فاکتور #${PersianFormatter.toPersianDigits(_currentInvoice.invoiceNumber)}'),
        actions: [
          // 1. Shutter / Image Export Button
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.camera),
            tooltip: 'عکس گرفتن از فاکتور (PNG با کیفیت ۴K)',
            onPressed: _isExporting ? null : _exportAsImage,
          ),
          // 2. PDF Export Button
          IconButton(
            icon: const Icon(LucideIcons.fileSpreadsheet),
            tooltip: 'صدور فایل رسمی PDF فاکتور',
            onPressed: _isExporting ? null : _exportAsPdf,
          ),
          // 3. Text Share Button
          IconButton(
            icon: const Icon(LucideIcons.share2),
            tooltip: 'اشتراک‌گذاری متن فاکتور',
            onPressed: _shareInvoiceText,
          ),
          // 4. Customize & Display Options
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: 'شخصی‌سازی نمایش و تراکم فاکتور',
            onPressed: _showTemplateOptionsModal,
          ),
          // 5. Edit Invoice Button
          IconButton(
            icon: const Icon(LucideIcons.edit3),
            tooltip: 'ویرایش فاکتور',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceEditorScreen(
                    invoiceToEdit: _currentInvoice,
                    isPurchase: _currentInvoice.isPurchase,
                  ),
                ),
              );
              if (res == true) {
                await storage.loadAll();
                final updated = storage.invoices.firstWhere(
                  (i) => i.id == _currentInvoice.id,
                  orElse: () => _currentInvoice,
                );
                setState(() => _currentInvoice = updated);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ==========================================
          // 1. TEMPLATE SELECTOR FLOATING STRIP
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: InvoiceDesignTemplate.values.map((template) {
                  final isSelected = _selectedTemplate == template;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        template.icon,
                        size: 14,
                        color: isSelected ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                      label: Text(template.labelFa),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.cardDarkElevated : AppColors.bgLight,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedTemplate = template);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ==========================================
          // 2. INVOICE PREVIEW CANVAS (WITH REPAINT BOUNDARY)
          // ==========================================
          Expanded(
            child: Container(
              color: isDark ? AppColors.bgDark : const Color(0xFFF1F5F9),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: RepaintBoundary(
                      key: _invoiceRepaintKey,
                      child: _buildActiveTemplate(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==========================================
          // 3. BOTTOM EXPORT TOOLBAR
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportAsImage,
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: const Text('عکس فاکتور (PNG)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportAsPdf,
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 16),
                    label: const Text('فایل PDF فاکتور', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      side: BorderSide(color: isDark ? AppColors.borderDarkStrong : AppColors.borderLightStrong),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
