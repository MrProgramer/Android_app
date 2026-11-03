import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../widgets/flat_card.dart';
import '../widgets/smart_price_input.dart';
import '../widgets/custom_badge.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? productToEdit;

  const ProductFormScreen({super.key, this.productToEdit});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService storage = StorageService();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _categoryController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _coverPriceController;
  late TextEditingController _piecesPerCartonController;
  late TextEditingController _packsPerCartonController;
  late TextEditingController _piecesPerPackController;
  late TextEditingController _leavesPerPieceController;
  late TextEditingController _stockPiecesController;
  late TextEditingController _unitTitleController;
  late TextEditingController _barcodeController;
  late TextEditingController _notesController;

  bool _isUnpackaged = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _codeController = TextEditingController(text: p?.code ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'عمومی');
    _purchasePriceController = TextEditingController(
      text: p != null && p.purchasePrice > 0 ? PersianFormatter.formatPrice(p.purchasePrice, includeUnit: false) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null && p.sellingPrice > 0 ? PersianFormatter.formatPrice(p.sellingPrice, includeUnit: false) : '',
    );
    _coverPriceController = TextEditingController(
      text: (p?.coverPrice != null && p!.coverPrice! > 0)
          ? PersianFormatter.formatPrice(p.coverPrice, includeUnit: false)
          : '',
    );
    _piecesPerCartonController = TextEditingController(
      text: p != null ? p.piecesPerCarton.toString() : '1',
    );
    _packsPerCartonController = TextEditingController(
      text: p?.packsPerCarton != null ? p!.packsPerCarton.toString() : '',
    );
    _piecesPerPackController = TextEditingController(
      text: p?.piecesPerPack != null ? p!.piecesPerPack.toString() : '',
    );
    _leavesPerPieceController = TextEditingController(
      text: p?.leavesPerPiece != null ? p!.leavesPerPiece.toString() : '',
    );
    _stockPiecesController = TextEditingController(
      text: p != null ? p.stockPieces.toString() : '0',
    );
    _unitTitleController = TextEditingController(text: p?.unitTitle ?? 'عدد');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _isUnpackaged = p?.isUnpackaged ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _coverPriceController.dispose();
    _piecesPerCartonController.dispose();
    _packsPerCartonController.dispose();
    _piecesPerPackController.dispose();
    _leavesPerPieceController.dispose();
    _stockPiecesController.dispose();
    _unitTitleController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get profitMargin {
    final buy = PersianFormatter.parseDouble(_purchasePriceController.text);
    final sell = PersianFormatter.parseDouble(_sellingPriceController.text);
    if (sell <= 0) return 0;
    return ((sell - buy) / sell) * 100;
  }

  void _addNewCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن دسته‌بندی جدید', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام دسته‌بندی جدید', hintText: 'مثلاً: شوینده و بهداشتی'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () async {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty) {
                if (!storage.categories.contains(newCat)) {
                  storage.categories.add(newCat);
                  await storage.saveCategories();
                }
                setState(() => _categoryController.text = newCat);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final ppc = PersianFormatter.parseInt(_piecesPerCartonController.text);
    final effectivePpc = ppc > 0 ? ppc : 1;
    final packs = int.tryParse(_packsPerCartonController.text);
    final ppp = int.tryParse(_piecesPerPackController.text);
    final leaves = int.tryParse(_leavesPerPieceController.text);

    final purchasePrice = PersianFormatter.parseDouble(_purchasePriceController.text);
    final sellingPrice = PersianFormatter.parseDouble(_sellingPriceController.text);
    final coverPrice = _coverPriceController.text.isNotEmpty
        ? PersianFormatter.parseDouble(_coverPriceController.text)
        : null;

    final stock = PersianFormatter.parseInt(_stockPiecesController.text);

    final isEditing = widget.productToEdit != null;
    final product = Product(
      id: isEditing ? widget.productToEdit!.id : 'prod-${const Uuid().v4().substring(0, 8)}',
      name: _nameController.text.trim(),
      code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'عمومی' : _categoryController.text.trim(),
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      coverPrice: coverPrice,
      piecesPerCarton: effectivePpc,
      packsPerCarton: packs,
      piecesPerPack: ppp,
      leavesPerPiece: leaves,
      stockPieces: stock,
      unitTitle: _unitTitleController.text.trim().isEmpty ? 'عدد' : _unitTitleController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isUnpackaged: _isUnpackaged,
      createdAt: isEditing ? widget.productToEdit!.createdAt : DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (isEditing) {
      await storage.updateProduct(product);
    } else {
      await storage.addProduct(product);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'مشخصات کالا با موفقیت ویرایش شد' : 'کالای جدید به انبار افزوده شد'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش مشخصات کالا' : 'افزودن کالای جدید به انبار'),
        actions: [
          TextButton.icon(
            onPressed: _saveProduct,
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('ذخیره کالا'),
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
            // 1. BASIC INFORMATION
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'اطلاعات اصلی و عنوان کالا',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      TextButton.icon(
                        onPressed: _addNewCategoryDialog,
                        icon: const Icon(LucideIcons.plus, size: 13),
                        label: const Text('دسته جدید', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'نام و عنوان تجاری کالا *',
                      hintText: 'مثلاً: آبنبات کپل کوچک توت فرنگی',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'نام کالا الزامی است' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'دسته‌بندی کالا *',
                            hintText: 'آبنبات، لواشک...',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'دسته‌بندی الزامی است' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _unitTitleController,
                          decoration: const InputDecoration(
                            labelText: 'واحد شمارش',
                            hintText: 'عدد، بسته',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick category selection chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: storage.categories.map((cat) {
                        final isSel = _categoryController.text == cat;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ActionChip(
                            label: Text(cat, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isSel
                                ? AppColors.primarySurface
                                : (isDark ? AppColors.cardDarkElevated : AppColors.bgLight),
                            side: BorderSide(color: isSel ? AppColors.primary : Colors.transparent),
                            onPressed: () => setState(() => _categoryController.text = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. PACKAGING SPECIFICATIONS
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مشخصات کارتن و بسته‌بندی',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _isUnpackaged,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isUnpackaged = v ?? false),
                          ),
                          const Text('کالای فله / بدون کارتن', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_isUnpackaged) ...[
                    TextFormField(
                      controller: _piecesPerCartonController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'تعداد کل دانه در هر کارتن *',
                        hintText: 'مثلاً: ۸۰۰',
                        helperText: 'مبنای محاسبات تعداد کارتن و دانه انبار',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'تعداد در کارتن الزامی است' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _packsPerCartonController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'تعداد بسته در کارتن',
                              hintText: 'مثلاً: ۴',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _piecesPerPackController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'تعداد دانه در هر بسته',
                              hintText: 'مثلاً: ۲۰۰',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _leavesPerPieceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'تعداد برگی (اختیاری)',
                              hintText: 'مثلاً: ۶',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. PRICING & MARGINS (WITH SMART PRICE INPUT & VERBAL WORDS)
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'قیمت‌گذاری و بهای تمام‌شده',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      if (profitMargin > 0)
                        CustomBadge(
                          text: 'حاشیه سود: ${PersianFormatter.toPersianDigits(profitMargin.toStringAsFixed(1))}٪',
                          textColor: AppColors.emerald,
                          backgroundColor: AppColors.emeraldSurface,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SmartPriceInput(
                    controller: _sellingPriceController,
                    label: 'قیمت فروش واحد (تومان)',
                    hintText: 'مثلاً: ۵,۸۰۰',
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SmartPriceInput(
                    controller: _purchasePriceController,
                    label: 'قیمت خرید واحد (تومان)',
                    hintText: 'مثلاً: ۴,۵۰۰',
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SmartPriceInput(
                    controller: _coverPriceController,
                    label: 'قیمت روی جلد / مصرف‌کننده (اختیاری)',
                    hintText: 'مثلاً: ۷,۰۰۰',
                    isRequired: false,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. STOCK & INVENTORY
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('موجودی انبار و شناسه', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockPiecesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'موجودی کل (دانه/عدد)',
                            hintText: 'مثلاً: ۴۰۰۰',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'کد کالا (اختیاری)',
                            hintText: 'مثلاً: P-102',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'بارکد کالا (اختیاری)',
                      hintText: '۶۲۶۰۰...',
                      prefixIcon: Icon(Icons.qr_code, size: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت یا شرایط نگهداری',
                      hintText: 'مثلاً: نگهداری در جای خشک و خنک',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isEditing ? 'ثبت و اعمال تغییرات کالا' : 'افزودن کالا به فهرست انبار',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
