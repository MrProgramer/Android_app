class CustomerPayment {
  final String id;
  final String customerId;
  final String customerName;
  final double amount; // مبلغ به تومان
  final String date; // تاریخ شمسی
  final String? time;
  final String paymentMethod; // card, bank_transfer, cash, check
  final String? type; // payment or payout
  final String? referenceNumber;
  final String? description;
  final int createdAt;

  CustomerPayment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.date,
    this.time,
    this.paymentMethod = 'card',
    this.type = 'payment',
    this.referenceNumber,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'amount': amount,
    'date': date,
    if (time != null) 'time': time,
    'paymentMethod': paymentMethod,
    if (type != null) 'type': type,
    if (referenceNumber != null) 'referenceNumber': referenceNumber,
    if (description != null) 'description': description,
    'createdAt': createdAt,
  };

  factory CustomerPayment.fromJson(Map<String, dynamic> json) => CustomerPayment(
    id: json['id']?.toString() ?? '',
    customerId: json['customerId']?.toString() ?? '',
    customerName: json['customerName']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    date: json['date']?.toString() ?? '',
    time: json['time']?.toString(),
    paymentMethod: json['paymentMethod']?.toString() ?? 'card',
    type: json['type']?.toString() ?? 'payment',
    referenceNumber: json['referenceNumber']?.toString(),
    description: json['description']?.toString(),
    createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
  );
}

class Customer {
  final String id;
  final String name;
  final String? company;
  final String customerType; // regular, distributor, supplier, both, partner
  final String phone;
  final String city;
  final String? address;
  final String? nationalCode;
  final double initialBalance; // مانده حساب اولیه: مثبت بدهکار، منفی بستانکار
  final double? balanceAdjustment;
  final String? balanceAdjustmentNotes;
  final double? creditLimit;
  final String? notes;
  final int createdAt;

  Customer({
    required this.id,
    required this.name,
    this.company,
    this.customerType = 'regular',
    required this.phone,
    required this.city,
    this.address,
    this.nationalCode,
    this.initialBalance = 0.0,
    this.balanceAdjustment,
    this.balanceAdjustmentNotes,
    this.creditLimit,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (company != null) 'company': company,
    'customerType': customerType,
    'phone': phone,
    'city': city,
    if (address != null) 'address': address,
    if (nationalCode != null) 'nationalCode': nationalCode,
    'initialBalance': initialBalance,
    if (balanceAdjustment != null) 'balanceAdjustment': balanceAdjustment,
    if (balanceAdjustmentNotes != null) 'balanceAdjustmentNotes': balanceAdjustmentNotes,
    if (creditLimit != null) 'creditLimit': creditLimit,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    company: json['company']?.toString(),
    customerType: json['customerType']?.toString() ?? 'regular',
    phone: json['phone']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    address: json['address']?.toString(),
    nationalCode: json['nationalCode']?.toString(),
    initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
    balanceAdjustment: (json['balanceAdjustment'] as num?)?.toDouble(),
    balanceAdjustmentNotes: json['balanceAdjustmentNotes']?.toString(),
    creditLimit: (json['creditLimit'] as num?)?.toDouble(),
    notes: json['notes']?.toString(),
    createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
  );
}
