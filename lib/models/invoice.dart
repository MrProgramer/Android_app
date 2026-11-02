class InvoiceExpense {
  final String id;
  final String title;
  final double amount;
  final String type; // freight, loss_waste, handling, damage, other
  final String action; // deduct, add, record_only
  final String sourceAccount; // cash, bank, none
  final String? notes;

  InvoiceExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.action = 'add',
    this.sourceAccount = 'none',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type,
    'action': action,
    'sourceAccount': sourceAccount,
    if (notes != null) 'notes': notes,
  };

  factory InvoiceExpense.fromJson(Map<String, dynamic> json) => InvoiceExpense(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    type: json['type']?.toString() ?? 'other',
    action: json['action']?.toString() ?? 'add',
    sourceAccount: json['sourceAccount']?.toString() ?? 'none',
    notes: json['notes']?.toString(),
  );
}

class InvoiceItem {
  final String id;
  final String productId;
  final String productName;
  final String? category;
  final String unitTitle;
  final int cartonsCount; // تعداد کارتن
  final int? packsCount; // تعداد بسته
  final int? piecesPerPack; // تعداد در بسته
  final int extraPieces; // دانه اضافه
  final int piecesPerCarton; // تعداد در هر کارتن
  final int totalPieces; // جمع کل دانه = (cartonsCount * piecesPerCarton) + extraPieces
  final double unitPurchasePrice; // قیمت خرید واحد
  final double unitSellingPrice; // قیمت فروش واحد
  final double? coverPrice; // قیمت روی جلد
  final double totalPrice; // مبلغ کل فروش این ردیف = totalPieces * unitSellingPrice
  final double totalPurchaseCost; // بهای تمام شده = totalPieces * unitPurchasePrice
  final double profitAmount; // سود = totalPrice - totalPurchaseCost
  final double profitPercentage;
  final String? customDescription;
  final bool isUnpackaged;
  final bool isCartonUnknown;

  InvoiceItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.category,
    this.unitTitle = 'عدد',
    required this.cartonsCount,
    this.packsCount,
    this.piecesPerPack,
    required this.extraPieces,
    required this.piecesPerCarton,
    required this.totalPieces,
    required this.unitPurchasePrice,
    required this.unitSellingPrice,
    this.coverPrice,
    required this.totalPrice,
    required this.totalPurchaseCost,
    required this.profitAmount,
    required this.profitPercentage,
    this.customDescription,
    this.isUnpackaged = false,
    this.isCartonUnknown = false,
  });

  // Helper factory to compute totalPieces, totalPrice, profit accurately
  factory InvoiceItem.calculate({
    required String id,
    required String productId,
    required String productName,
    String? category,
    String unitTitle = 'عدد',
    required int cartonsCount,
    int? packsCount,
    int? piecesPerPack,
    required int extraPieces,
    required int piecesPerCarton,
    required double unitPurchasePrice,
    required double unitSellingPrice,
    double? coverPrice,
    String? customDescription,
    bool isUnpackaged = false,
    bool isCartonUnknown = false,
    bool isPurchaseInvoice = false,
  }) {
    final effectivePpc = piecesPerCarton > 0 ? piecesPerCarton : 1;
    final totalP = isUnpackaged
        ? extraPieces
        : (cartonsCount * effectivePpc) + extraPieces;

    final double lineTotal = isPurchaseInvoice
        ? (totalP * unitPurchasePrice)
        : (totalP * unitSellingPrice);

    final double totalCost = totalP * unitPurchasePrice;
    final double profit = lineTotal - totalCost;
    final double profitPct = lineTotal > 0 ? (profit / lineTotal) * 100 : 0.0;

    return InvoiceItem(
      id: id,
      productId: productId,
      productName: productName,
      category: category,
      unitTitle: unitTitle,
      cartonsCount: cartonsCount,
      packsCount: packsCount,
      piecesPerPack: piecesPerPack,
      extraPieces: extraPieces,
      piecesPerCarton: effectivePpc,
      totalPieces: totalP,
      unitPurchasePrice: unitPurchasePrice,
      unitSellingPrice: unitSellingPrice,
      coverPrice: coverPrice,
      totalPrice: lineTotal,
      totalPurchaseCost: totalCost,
      profitAmount: profit,
      profitPercentage: profitPct,
      customDescription: customDescription,
      isUnpackaged: isUnpackaged,
      isCartonUnknown: isCartonUnknown,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    if (category != null) 'category': category,
    'unitTitle': unitTitle,
    'cartonsCount': cartonsCount,
    if (packsCount != null) 'packsCount': packsCount,
    if (piecesPerPack != null) 'piecesPerPack': piecesPerPack,
    'extraPieces': extraPieces,
    'piecesPerCarton': piecesPerCarton,
    'totalPieces': totalPieces,
    'unitPurchasePrice': unitPurchasePrice,
    'unitSellingPrice': unitSellingPrice,
    if (coverPrice != null) 'coverPrice': coverPrice,
    'totalPrice': totalPrice,
    'totalPurchaseCost': totalPurchaseCost,
    'profitAmount': profitAmount,
    'profitPercentage': profitPercentage,
    if (customDescription != null) 'customDescription': customDescription,
    'isUnpackaged': isUnpackaged,
    'isCartonUnknown': isCartonUnknown,
  };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final cartons = (json['cartonsCount'] as num?)?.toInt() ?? 0;
    final extras = (json['extraPieces'] as num?)?.toInt() ?? 0;
    final ppc = (json['piecesPerCarton'] as num?)?.toInt() ?? 1;
    final totalP = (json['totalPieces'] as num?)?.toInt() ?? ((cartons * ppc) + extras);
    final unitSell = (json['unitSellingPrice'] as num?)?.toDouble() ?? 0.0;
    final unitBuy = (json['unitPurchasePrice'] as num?)?.toDouble() ?? 0.0;
    final totalPr = (json['totalPrice'] as num?)?.toDouble() ?? (totalP * unitSell);
    final totalCost = (json['totalPurchaseCost'] as num?)?.toDouble() ?? (totalP * unitBuy);

    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      category: json['category']?.toString(),
      unitTitle: json['unitTitle']?.toString() ?? 'عدد',
      cartonsCount: cartons,
      packsCount: (json['packsCount'] as num?)?.toInt(),
      piecesPerPack: (json['piecesPerPack'] as num?)?.toInt(),
      extraPieces: extras,
      piecesPerCarton: ppc,
      totalPieces: totalP,
      unitPurchasePrice: unitBuy,
      unitSellingPrice: unitSell,
      coverPrice: (json['coverPrice'] as num?)?.toDouble(),
      totalPrice: totalPr,
      totalPurchaseCost: totalCost,
      profitAmount: (json['profitAmount'] as num?)?.toDouble() ?? (totalPr - totalCost),
      profitPercentage: (json['profitPercentage'] as num?)?.toDouble() ?? 0.0,
      customDescription: json['customDescription']?.toString(),
      isUnpackaged: json['isUnpackaged'] == true,
      isCartonUnknown: json['isCartonUnknown'] == true,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String date; // تاریخ شمسی مانند "1405/05/14"
  final String time; // زمان مانند "13:48"
  final int? timestamp;
  final String type; // 'sale' or 'purchase'
  final String paymentStatus; // 'cash', 'credit', 'partial'
  final double paidAmount;
  final double remainingAmount;
  final String paymentAccount; // 'cash', 'bank'
  final String? paymentMethodDetails;
  final bool isDraft;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String customerCity;
  final String? customerAddress;
  final String? customerType;
  final String salesType;
  final String paymentMethod;
  final String previousBalance;
  final String finalCustomerBalance;
  final List<InvoiceItem> items;
  final double subtotal; // جمع ردیف‌ها
  final double discount;
  final bool hasDiscount;
  final double? discountPercent;
  final bool showCoverPrice;
  final double tax;
  final double finalAmount; // مبلغ نهایی قابل پرداخت
  final List<String>? offsetReturnIds;
  final double? offsetReturnsTotal;
  final List<InvoiceExpense> expenses;
  final double? expensesTotalDeduction;
  final double? expensesTotalAddition;
  final String? notes;
  final int createdAt;
  final int? updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.time,
    this.timestamp,
    required this.type,
    this.paymentStatus = 'cash',
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.paymentAccount = 'bank',
    this.paymentMethodDetails,
    this.isDraft = false,
    this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.customerCity = '',
    this.customerAddress,
    this.customerType,
    this.salesType = 'نقدی',
    this.paymentMethod = 'نقدی (تسویه شده)',
    this.previousBalance = 'بی‌حساب',
    this.finalCustomerBalance = 'تسویه شده / بی‌حساب',
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.hasDiscount = false,
    this.discountPercent,
    this.showCoverPrice = true,
    this.tax = 0.0,
    required this.finalAmount,
    this.offsetReturnIds,
    this.offsetReturnsTotal,
    this.expenses = const [],
    this.expensesTotalDeduction,
    this.expensesTotalAddition,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isSale => type == 'sale';
  bool get isPurchase => type == 'purchase';

  // Total quantity of pieces across all items
  int get totalPiecesCount => items.fold(0, (sum, it) => sum + it.totalPieces);

  // Total gross profit of invoice
  double get totalProfit => items.fold(0.0, (sum, it) => sum + it.profitAmount);

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? date,
    String? time,
    int? timestamp,
    String? type,
    String? paymentStatus,
    double? paidAmount,
    double? remainingAmount,
    String? paymentAccount,
    String? paymentMethodDetails,
    bool? isDraft,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerCity,
    String? customerAddress,
    String? customerType,
    String? salesType,
    String? paymentMethod,
    String? previousBalance,
    String? finalCustomerBalance,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discount,
    bool? hasDiscount,
    double? discountPercent,
    bool? showCoverPrice,
    double? tax,
    double? finalAmount,
    List<String>? offsetReturnIds,
    double? offsetReturnsTotal,
    List<InvoiceExpense>? expenses,
    double? expensesTotalDeduction,
    double? expensesTotalAddition,
    String? notes,
    int? createdAt,
    int? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentAccount: paymentAccount ?? this.paymentAccount,
      paymentMethodDetails: paymentMethodDetails ?? this.paymentMethodDetails,
      isDraft: isDraft ?? this.isDraft,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerCity: customerCity ?? this.customerCity,
      customerAddress: customerAddress ?? this.customerAddress,
      customerType: customerType ?? this.customerType,
      salesType: salesType ?? this.salesType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      previousBalance: previousBalance ?? this.previousBalance,
      finalCustomerBalance: finalCustomerBalance ?? this.finalCustomerBalance,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      showCoverPrice: showCoverPrice ?? this.showCoverPrice,
      tax: tax ?? this.tax,
      finalAmount: finalAmount ?? this.finalAmount,
      offsetReturnIds: offsetReturnIds ?? this.offsetReturnIds,
      offsetReturnsTotal: offsetReturnsTotal ?? this.offsetReturnsTotal,
      expenses: expenses ?? this.expenses,
      expensesTotalDeduction: expensesTotalDeduction ?? this.expensesTotalDeduction,
      expensesTotalAddition: expensesTotalAddition ?? this.expensesTotalAddition,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'date': date,
    'time': time,
    if (timestamp != null) 'timestamp': timestamp,
    'type': type,
    'paymentStatus': paymentStatus,
    'paidAmount': paidAmount,
    'remainingAmount': remainingAmount,
    'paymentAccount': paymentAccount,
    if (paymentMethodDetails != null) 'paymentMethodDetails': paymentMethodDetails,
    'isDraft': isDraft,
    if (customerId != null) 'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerCity': customerCity,
    if (customerAddress != null) 'customerAddress': customerAddress,
    if (customerType != null) 'customerType': customerType,
    'salesType': salesType,
    'paymentMethod': paymentMethod,
    'previousBalance': previousBalance,
    'finalCustomerBalance': finalCustomerBalance,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'hasDiscount': hasDiscount,
    if (discountPercent != null) 'discountPercent': discountPercent,
    'showCoverPrice': showCoverPrice,
    'tax': tax,
    'finalAmount': finalAmount,
    if (offsetReturnIds != null) 'offsetReturnIds': offsetReturnIds,
    if (offsetReturnsTotal != null) 'offsetReturnsTotal': offsetReturnsTotal,
    'expenses': expenses.map((e) => e.toJson()).toList(),
    if (expensesTotalDeduction != null) 'expensesTotalDeduction': expensesTotalDeduction,
    if (expensesTotalAddition != null) 'expensesTotalAddition': expensesTotalAddition,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList();

    final rawExpenses = json['expenses'] as List<dynamic>? ?? [];
    final expensesList = rawExpenses.map((e) => InvoiceExpense.fromJson(e as Map<String, dynamic>)).toList();

    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt(),
      type: json['type']?.toString() ?? 'sale',
      paymentStatus: json['paymentStatus']?.toString() ?? 'cash',
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentAccount: json['paymentAccount']?.toString() ?? 'bank',
      paymentMethodDetails: json['paymentMethodDetails']?.toString(),
      isDraft: json['isDraft'] == true,
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerCity: json['customerCity']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString(),
      customerType: json['customerType']?.toString(),
      salesType: json['salesType']?.toString() ?? 'نقدی',
      paymentMethod: json['paymentMethod']?.toString() ?? 'نقدی',
      previousBalance: json['previousBalance']?.toString() ?? 'بی‌حساب',
      finalCustomerBalance: json['finalCustomerBalance']?.toString() ?? 'تسویه شده / بی‌حساب',
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      hasDiscount: json['hasDiscount'] == true,
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      showCoverPrice: json['showCoverPrice'] != false,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      offsetReturnIds: (json['offsetReturnIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      offsetReturnsTotal: (json['offsetReturnsTotal'] as num?)?.toDouble(),
      expenses: expensesList,
      expensesTotalDeduction: (json['expensesTotalDeduction'] as num?)?.toDouble(),
      expensesTotalAddition: (json['expensesTotalAddition'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
      createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );
  }
}
