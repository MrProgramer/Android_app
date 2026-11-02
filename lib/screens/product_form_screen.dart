import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../utils/persian_formatter.dart';
import '../widgets/flat_card.dart';

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
  late TextEditingController _categoryController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _coverPriceController;
  late TextEditingController _piecesPerCartonController;
  late TextEditingController _packsPerCartonController;
  late TextEditingController _piecesPerPackController;
  late TextEditingController _stockPiecesController;
  late TextEditingController _unitTitleController;
  late TextEditingController _notesController;

  bool _isUnpackaged = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'عمومی');
    _purchasePriceController = TextEditingController(
      text: p != null ? PersianFormatter.formatPrice(p.purchasePrice, includeUnit: false) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? PersianFormatter.formatPrice(p.sellingPrice, includeUnit: false) : '',
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
    _stockPiecesController = TextEditingController(
      text: p != null ? p.stockPieces.toString() : '0',
    );
    _unitTitleController = TextEditingController(text: p?.unitTitle ?? 'عدد');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _isUnpackaged = p?.isUnpackaged ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _coverPriceController.dispose();
    _piecesPerCartonController.dispose();
    _packsPerCartonController.dispose();
    _piecesPerPackController.dispose();
    _stockPiecesController.dispose();
    _unitTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final ppc = PersianFormatter.parseInt(_piecesPerCartonController.text);
    final effectivePpc = ppc > 0 ? ppc : 1;
    final packs = int.tryParse(_packsPerCartonController.text);
    final ppp = int.tryParse(_piecesPerPackController.text);

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
      category: _categoryController.text.trim().isEmpty ? 'عمومی' : _categoryController.text.trim(),
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      coverPrice: coverPrice,
      piecesPerCarton: effectivePpc,
      packsPerCarton: packs,
      piecesPerPack: ppp,
      stockPieces: stock,
      unitTitle: _unitTitleController.text.trim().isEmpty ? 'عدد' : _unitTitleController.text.trim(),
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
          content: Text(isEditing ? 'کالا با موفقیت ویرایش شد' : 'کالای جدید با موفقیت افزوده شد'),
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
        title: Text(isEditing ? 'ویرایش مشخصات کالا' : 'افزودن کالای جدید'),
        actions: [
          TextButton.icon(
            onPressed: _saveProduct,
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('ذخیره'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
            // Basic Info Card
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اطلاعات اصلی محصول',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'نام و عنوان کالا *',
                      hintText: 'مثلاً: آبنبات کپل کوچک توت فرنگی',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'لطفاً نام کالا را وارد کنید' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'دسته‌بندی *',
                            hintText: 'مثلاً: آبنبات',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'دسته‌بندی الزامی است' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 10),
                  // Category quick select chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: storage.categories.map((cat) {
                      return ActionChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        backgroundColor: _categoryController.text == cat
                            ? AppColors.primarySurface
                            : (isDark ? AppColors.cardDarkElevated : AppColors.bgLight),
                        side: BorderSide(
                          color: _categoryController.text == cat ? AppColors.primary : Colors.transparent,
                        ),
                        onPressed: () {
                          setState(() {
                            _categoryController.text = cat;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Packaging Specifications Card
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مشخصات بسته‌بندی و کارتن',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
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
                        const SizedBox(width: 10),
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
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Pricing & Margins Card
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قیمت‌گذاری و بهای تمام‌شده (تومان)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'قیمت خرید (تومان) *',
                            hintText: 'مثلاً: ۴,۵۰۰',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'قیمت خرید الزامی است' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'قیمت فروش (تومان) *',
                            hintText: 'مثلاً: ۵,۸۰۰',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'قیمت فروش الزامی است' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _coverPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'قیمت درج‌شده روی جلد / مصرف‌کننده (اختیاری)',
                      hintText: 'مثلاً: ۷,۰۰۰',
                      helperText: 'جهت نمایش در فاکتور چاپی فروش',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stock & Inventory Card
            FlatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'موجودی فعلی انبار',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockPiecesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'تعداد کل دانه موجود در انبار',
                      hintText: 'مثلاً: ۴۰۰۰',
                      helperText: 'بر اساس تعداد کل دانه محاسبه می‌شود',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'توضیحات و یادداشت (اختیاری)',
                      hintText: 'مثلاً: برند معتبر، نگهداری در جای خشک و خنک',
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
                isEditing ? 'ثبت تغییرات کالا' : 'افزودن کالا به انبار',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
