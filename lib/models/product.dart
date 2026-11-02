class Product {
  final String id;
  final String name;
  final String? code;
  final String category;
  final double purchasePrice; // قیمت خرید به تومان
  final double sellingPrice; // قیمت فروش به تومان
  final double? coverPrice; // قیمت مصرف‌کننده / روی جلد
  final int piecesPerCarton; // تعداد در کارتن
  final int? packsPerCarton; // تعداد بسته در کارتن
  final int? piecesPerPack; // تعداد در هر بسته
  final int? leavesPerPiece; // تعداد برگی/دانه‌ای
  final int stockPieces; // موجودی کل انبار به عدد/دانه
  final String unitTitle; // پیش‌فرض: عدد
  final String? barcode;
  final int? minOrderCartons;
  final String? notes;
  final bool isUnpackaged;
  final bool isCartonUnknown;
  final int? createdAt;
  final int? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.code,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    this.coverPrice,
    required this.piecesPerCarton,
    this.packsPerCarton,
    this.piecesPerPack,
    this.leavesPerPiece,
    required this.stockPieces,
    this.unitTitle = 'عدد',
    this.barcode,
    this.minOrderCartons,
    this.notes,
    this.isUnpackaged = false,
    this.isCartonUnknown = false,
    this.createdAt,
    this.updatedAt,
  });

  // Calculate cartons and extra pieces
  int get cartons => piecesPerCarton > 0 ? stockPieces ~/ piecesPerCarton : 0;
  int get extraPieces => piecesPerCarton > 0 ? stockPieces % piecesPerCarton : stockPieces;

  // Breakdown text: e.g. "۵ کارتن و ۲۰ دانه" or "۵ کارتن" or "۲۰ عدد"
  String get stockFormatted {
    if (isUnpackaged || piecesPerCarton <= 1) {
      return '$stockPieces $unitTitle';
    }
    if (cartons > 0 && extraPieces > 0) {
      return '$cartons کارتن و $extraPieces دانه';
    } else if (cartons > 0) {
      return '$cartons کارتن';
    } else {
      return '$extraPieces $unitTitle';
    }
  }

  // Margin percentage
  double get profitMarginPercent {
    if (sellingPrice <= 0) return 0;
    return ((sellingPrice - purchasePrice) / sellingPrice) * 100;
  }

  Product copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    double? coverPrice,
    int? piecesPerCarton,
    int? packsPerCarton,
    int? piecesPerPack,
    int? leavesPerPiece,
    int? stockPieces,
    String? unitTitle,
    String? barcode,
    int? minOrderCartons,
    String? notes,
    bool? isUnpackaged,
    bool? isCartonUnknown,
    int? createdAt,
    int? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      coverPrice: coverPrice ?? this.coverPrice,
      piecesPerCarton: piecesPerCarton ?? this.piecesPerCarton,
      packsPerCarton: packsPerCarton ?? this.packsPerCarton,
      piecesPerPack: piecesPerPack ?? this.piecesPerPack,
      leavesPerPiece: leavesPerPiece ?? this.leavesPerPiece,
      stockPieces: stockPieces ?? this.stockPieces,
      unitTitle: unitTitle ?? this.unitTitle,
      barcode: barcode ?? this.barcode,
      minOrderCartons: minOrderCartons ?? this.minOrderCartons,
      notes: notes ?? this.notes,
      isUnpackaged: isUnpackaged ?? this.isUnpackaged,
      isCartonUnknown: isCartonUnknown ?? this.isCartonUnknown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      if (coverPrice != null) 'coverPrice': coverPrice,
      'piecesPerCarton': piecesPerCarton,
      if (packsPerCarton != null) 'packsPerCarton': packsPerCarton,
      if (piecesPerPack != null) 'piecesPerPack': piecesPerPack,
      if (leavesPerPiece != null) 'leavesPerPiece': leavesPerPiece,
      'stockPieces': stockPieces,
      'unitTitle': unitTitle,
      if (barcode != null) 'barcode': barcode,
      if (minOrderCartons != null) 'minOrderCartons': minOrderCartons,
      if (notes != null) 'notes': notes,
      'isUnpackaged': isUnpackaged,
      'isCartonUnknown': isCartonUnknown,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      category: json['category']?.toString() ?? 'عمومی',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      coverPrice: (json['coverPrice'] as num?)?.toDouble(),
      piecesPerCarton: (json['piecesPerCarton'] as num?)?.toInt() ?? 1,
      packsPerCarton: (json['packsPerCarton'] as num?)?.toInt(),
      piecesPerPack: (json['piecesPerPack'] as num?)?.toInt(),
      leavesPerPiece: (json['leavesPerPiece'] as num?)?.toInt(),
      stockPieces: (json['stockPieces'] as num?)?.toInt() ?? 0,
      unitTitle: json['unitTitle']?.toString() ?? 'عدد',
      barcode: json['barcode']?.toString(),
      minOrderCartons: (json['minOrderCartons'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      isUnpackaged: json['isUnpackaged'] == true,
      isCartonUnknown: json['isCartonUnknown'] == true,
      createdAt: (json['createdAt'] as num?)?.toInt(),
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );
  }
}
