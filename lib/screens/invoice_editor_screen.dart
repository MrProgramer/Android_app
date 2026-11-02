import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../utils/persian_date_helper.dart';
import '../widgets/flat_card.dart';
import '../widgets/custom_badge.dart';

class InvoiceEditorScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;
  final bool isPurchase;

  const InvoiceEditorScreen({
    super.key,
    this.invoiceToEdit,
    this.isPurchase = false,
  });

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  final StorageService storage = StorageService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _invoiceNumberController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerCityController;
  late TextEditingController _discountController;
  late TextEditingController _taxController;
  late TextEditingController _paidAmountController;
  late TextEditingController _notesController;

  String? _selectedCustomerId;
  String _paymentStatus = 'cash'; // 'cash', 'credit', 'partial'
  String _paymentAccount = 'bank'; // 'bank', 'cash'
  bool _isDraft = false;
  bool _showCoverPrice = true;

  List<InvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    final inv = widget.invoiceToEdit;

    // Generate new invoice number if new
    String invNumber = inv?.invoiceNumber ?? '';
    if (invNumber.isEmpty) {
      final lastNum = storage.invoices.isNotEmpty
          ? int.tryParse(storage.invoices.first.invoiceNumber) ?? 1000
          : 1000;
      invNumber = (lastNum + 1).toString();
    }

    _invoiceNumberController = TextEditingController(text: invNumber);
    _dateController = TextEditingController(text: inv?.date ?? PersianDateHelper.getCurrentJalaliDate());
    _timeController = TextEditingController(text: inv?.time ?? PersianDateHelper.getCurrentTime());
    _customerNameController = TextEditingController(text: inv?.customerName ?? '');
    _customerPhoneController = TextEditingController(text: inv?.customerPhone ?? '');
    _customerCityController = TextEditingController(text: inv?.customerCity ?? '');
    _discountController = TextEditingController(
      text: inv != null && inv.discount > 0 ? PersianFormatter.formatPrice(inv.discount, includeUnit: false) : '',
    );
    _taxController = TextEditingController(
      text: inv != null && inv.tax > 0 ? PersianFormatter.formatPrice(inv.tax, includeUnit: false) : '',
    );
    _paidAmountController = TextEditingController(
      text: inv != null && inv.paidAmount > 0 ? PersianFormatter.formatPrice(inv.paidAmount, includeUnit: false) : '',
    );
    _notesController = TextEditingController(text: inv?.notes ?? '');

    _selectedCustomerId = inv?.customerId;
    _paymentStatus = inv?.paymentStatus ?? 'cash';
    _paymentAccount = inv?.paymentAccount ?? 'bank';
    _isDraft = inv?.isDraft ?? false;
    _showCoverPrice = inv?.showCoverPrice ?? true;

    if (inv != null) {
      _items = List.from(inv.items);
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerCityController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Financial Calculations
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get discount => PersianFormatter.parseDouble(_discountController.text);
  double get tax => PersianFormatter.parseDouble(_taxController.text);
  double get finalAmount => (subtotal - discount + tax).clamp(0.0, 999999999999.0);

  double get paidAmount {
    if (_paymentStatus == 'cash') return finalAmount;
    if (_paymentStatus == 'credit') return 0.0;
    return PersianFormatter.parseDouble(_paidAmountController.text);
  }

  double get remainingAmount => (finalAmount - paidAmount).clamp(0.0, 999999999999.0);

  // --- Add Product Row Dialog ---
  void _openAddProductDialog() {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final availableProds = storage.products.where((p) {
              return search.isEmpty ||
                  p.name.toLowerCase().contains(search.toLowerCase()) ||
                  p.category.toLowerCase().contains(search.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'انتخاب کالا برای فاکتور',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'جستجوی نام کالا یا دسته‌بندی...',
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                    ),
                    onChanged: (v) => setModalState(() => search = v),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: availableProds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final prod = availableProds[idx];
                        final isAlreadyAdded = _items.any((it) => it.productId == prod.id);

                        return FlatCard(
                          padding: const EdgeInsets.all(12),
                          onTap: () {
                            Navigator.pop(ctx);
                            _openConfigureItemDialog(prod);
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(LucideIcons.package, size: 16, color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'موجودی: ${prod.stockFormatted} • هر کارتن: ${PersianFormatter.toPersianDigits(prod.piecesPerCarton)} عدد',
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
                                    PersianFormatter.formatPrice(
                                      widget.isPurchase ? prod.purchasePrice : prod.sellingPrice,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                                    ),
                                  ),
                                  if (isAlreadyAdded) ...[
                                    const SizedBox(height: 4),
                                    const CustomBadge(
                                      text: 'افزوده شده',
                                      textColor: AppColors.amber,
                                      backgroundColor: AppColors.amberSurface,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Configure Quantities & Prices for a line item
  void _openConfigureItemDialog(Product product, {InvoiceItem? existingItem}) {
    final cartonsController = TextEditingController(
      text: existingItem != null ? existingItem.cartonsCount.toString() : '1',
    );
    final extraPiecesController = TextEditingController(
      text: existingItem != null ? existingItem.extraPieces.toString() : '0',
    );
    final unitPriceController = TextEditingController(
      text: existingItem != null
          ? PersianFormatter.formatPrice(
              widget.isPurchase ? existingItem.unitPurchasePrice : existingItem.unitSellingPrice,
              includeUnit: false,
            )
          : PersianFormatter.formatPrice(
              widget.isPurchase ? product.purchasePrice : product.sellingPrice,
              includeUnit: false,
            ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cartons = PersianFormatter.parseInt(cartonsController.text);
            final extras = PersianFormatter.parseInt(extraPiecesController.text);
            final totalPieces = product.isUnpackaged
                ? extras
                : (cartons * product.piecesPerCarton) + extras;
            final unitPrice = PersianFormatter.parseDouble(unitPriceController.text);
            final rowTotal = totalPieces * unitPrice;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'هر کارتن: ${PersianFormatter.toPersianDigits(product.piecesPerCarton)} عدد' +
                          (!widget.isPurchase ? ' • موجودی انبار: ${product.stockFormatted}' : ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (!product.isUnpackaged && product.piecesPerCarton > 1) ...[
                          Expanded(
                            child: TextFormField(
                              controller: cartonsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'تعداد کارتن',
                                hintText: 'مثلاً: ۵',
                              ),
                              onChanged: (_) => setSheetState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TextFormField(
                            controller: extraPiecesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: product.isUnpackaged ? 'تعداد دانه / عدد' : 'دانه اضافه',
                              hintText: 'مثلاً: ۲۰',
                            ),
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: unitPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.isPurchase ? 'قیمت خرید واحد (تومان)' : 'قیمت فروش واحد (تومان)',
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // Summary calculation container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDarkElevated : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('جمع دانه‌ها:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              Text(
                                '${PersianFormatter.toPersianDigits(totalPieces)} ${product.unitTitle}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('مبلغ کل ردیف:', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              Text(
                                PersianFormatter.formatPrice(rowTotal),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (totalPieces <= 0) return;

                          final newItem = InvoiceItem.calculate(
                            id: existingItem?.id ?? const Uuid().v4(),
                            productId: product.id,
                            productName: product.name,
                            category: product.category,
                            unitTitle: product.unitTitle,
                            cartonsCount: cartons,
                            packsCount: product.packsPerCarton,
                            piecesPerPack: product.piecesPerPack,
                            extraPieces: extras,
                            piecesPerCarton: product.piecesPerCarton,
                            unitPurchasePrice: widget.isPurchase ? unitPrice : product.purchasePrice,
                            unitSellingPrice: widget.isPurchase ? product.sellingPrice : unitPrice,
                            coverPrice: product.coverPrice,
                            isUnpackaged: product.isUnpackaged,
                            isPurchaseInvoice: widget.isPurchase,
                          );

                          setState(() {
                            final idx = _items.indexWhere((it) => it.productId == product.id);
                            if (idx != -1) {
                              _items[idx] = newItem;
                            } else {
                              _items.add(newItem);
                            }
                          });

                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          existingItem != null ? 'بروزرسانی ردیف' : 'افزودن به فاکتور',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Select Customer Dialog ---
  void _openCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('انتخاب طرف‌حساب / مشتری', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: storage.customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = storage.customers[index];
                    return FlatCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        setState(() {
                          _selectedCustomerId = c.id;
                          _customerNameController.text = c.name;
                          _customerPhoneController.text = c.phone;
                          _customerCityController.text = c.city;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${c.phone} • ${c.city}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            ],
                          ),
                          CustomBadge(
                            text: c.customerType == 'supplier' ? 'تامین‌کننده' : (c.customerType == 'distributor' ? 'پخش' : 'مشتری'),
                            textColor: AppColors.primaryDark,
                            backgroundColor: AppColors.primarySurface,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Save Invoice ---
  void _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حداقل یک قلم کالا به فاکتور اضافه کنید'),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    final isEditing = widget.invoiceToEdit != null;
    final invId = isEditing ? widget.invoiceToEdit!.id : 'inv-${const Uuid().v4().substring(0, 8)}';

    final invoice = Invoice(
      id: invId,
      invoiceNumber: _invoiceNumberController.text.trim(),
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      type: widget.isPurchase ? 'purchase' : 'sale',
      paymentStatus: _paymentStatus,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      paymentAccount: _paymentAccount,
      isDraft: _isDraft,
      customerId: _selectedCustomerId,
      customerName: _customerNameController.text.trim().isEmpty ? 'مشتری متفرقه' : _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      customerCity: _customerCityController.text.trim(),
      items: _items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      finalAmount: finalAmount,
      showCoverPrice: _showCoverPrice,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: isEditing ? widget.invoiceToEdit!.createdAt : DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await storage.saveInvoice(invoice);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isDraft ? 'پیش‌نویس فاکتور ذخیره شد' : 'فاکتور با موفقیت ثبت و انبار بروزرسانی شد'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.invoiceToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPurchase
              ? (isEditing ? 'ویرایش فاکتور خرید / ورود به انبار' : 'صدور فاکتور خرید / ورود به انبار')
              : (isEditing ? 'ویرایش فاکتور فروش' : 'صدور فاکتور فروش'),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveInvoice,
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('ثبت فاکتور'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Info Card (Invoice Number & Date)
            FlatCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNumberController,
                          decoration: const InputDecoration(labelText: 'شماره فاکتور *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'شماره فاکتور الزامی است' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(labelText: 'تاریخ (شمسی) *'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _timeController,
                          decoration: const InputDecoration(labelText: 'ساعت'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Customer Info Card
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isPurchase ? 'مشخصات تامین‌کننده / فروشنده' : 'مشخصات خریدار / مشتری',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        onPressed: _openCustomerPicker,
                        icon: const Icon(LucideIcons.users, size: 14),
                        label: const Text('انتخاب از لیست', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: widget.isPurchase ? 'نام شرکت یا شخص تامین‌کننده *' : 'نام مشتری / طرف‌حساب *',
                      hintText: 'مثلاً: صابر کریمی',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'نام طرف‌حساب الزامی است' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _customerPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'شماره تماس', hintText: '0912...'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _customerCityController,
                          decoration: const InputDecoration(labelText: 'شهر / آدرس', hintText: 'تهران'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Items Table Card
            FlatCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اقلام و کالاهای فاکتور (${PersianFormatter.toPersianDigits(_items.length)})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openAddProductDialog,
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text('افزودن کالا', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Text(
                        'هیچ کالایی به این فاکتور اضافه نشده است.\nدکمه «افزودن کالا» را لمس کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final prod = storage.products.firstWhere(
                          (p) => p.id == item.productId,
                          orElse: () => Product(
                            id: item.productId,
                            name: item.productName,
                            category: item.category ?? 'عمومی',
                            purchasePrice: item.unitPurchasePrice,
                            sellingPrice: item.unitSellingPrice,
                            piecesPerCarton: item.piecesPerCarton,
                            stockPieces: 0,
                          ),
                        );

                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${PersianFormatter.formatStockBreakdown(item.totalPieces, item.piecesPerCarton, unitTitle: item.unitTitle)} ' +
                                        '(${PersianFormatter.toPersianDigits(item.totalPieces)} ${item.unitTitle}) × ' +
                                        PersianFormatter.formatPrice(widget.isPurchase ? item.unitPurchasePrice : item.unitSellingPrice),
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
                                  PersianFormatter.formatPrice(item.totalPrice),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.edit2, size: 14),
                                      onPressed: () => _openConfigureItemDialog(prod, existingItem: item),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.rose),
                                      onPressed: () {
                                        setState(() {
                                          _items.removeAt(index);
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
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

            const SizedBox(height: 14),

            // Financial Summary Card
            FlatCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('جمع اقلام فاکتور:', style: TextStyle(fontSize: 13)),
                      Text(
                        PersianFormatter.formatPrice(subtotal),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'تخفیف (تومان)', hintText: '۰'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'مالیات / عوارض', hintText: '۰'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مبلغ نهایی قابل پرداخت:',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        PersianFormatter.formatPrice(finalAmount),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Payment Status & Account Card
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('وضعیت تسویه و پرداخت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('نقدی (تسویه)')),
                          selected: _paymentStatus == 'cash',
                          selectedColor: AppColors.emerald,
                          labelStyle: TextStyle(
                            color: _paymentStatus == 'cash' ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _paymentStatus = 'cash');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('نسیه (بدهی)')),
                          selected: _paymentStatus == 'credit',
                          selectedColor: AppColors.rose,
                          labelStyle: TextStyle(
                            color: _paymentStatus == 'credit' ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _paymentStatus = 'credit');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('بیعانه / بخشی')),
                          selected: _paymentStatus == 'partial',
                          selectedColor: AppColors.amber,
                          labelStyle: TextStyle(
                            color: _paymentStatus == 'partial' ? Colors.white : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _paymentStatus = 'partial');
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_paymentStatus == 'partial') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'مبلغ پرداختی نقدی / بیعانه (تومان)'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'مانده بدهی این فاکتور: ${PersianFormatter.formatPrice(remainingAmount)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Account selector
                  Row(
                    children: [
                      const Text('حساب مالی: ', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('بانک / پوز', style: TextStyle(fontSize: 11)),
                        selected: _paymentAccount == 'bank',
                        selectedColor: AppColors.primary,
                        onSelected: (v) => setState(() => _paymentAccount = 'bank'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('صندوق نقدی', style: TextStyle(fontSize: 11)),
                        selected: _paymentAccount == 'cash',
                        selectedColor: AppColors.primary,
                        onSelected: (v) => setState(() => _paymentAccount = 'cash'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Options & Draft Switch Card
            FlatCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('ذخیره به عنوان پیش‌نویس', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('در حالت پیش‌نویس از موجودی انبار کسر یا اضافه نمی‌شود', style: TextStyle(fontSize: 11)),
                    value: _isDraft,
                    activeColor: AppColors.amber,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isDraft = v),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('نمایش قیمت روی جلد در پیش‌نمایش چاپی', style: TextStyle(fontSize: 13)),
                    value: _showCoverPrice,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _showCoverPrice = v),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'توضیحات و شرایط فاکتور (اختیاری)'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isDraft ? 'ذخیره پیش‌نویس فاکتور' : 'ثبت قطعی فاکتور و بروزرسانی انبار',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
