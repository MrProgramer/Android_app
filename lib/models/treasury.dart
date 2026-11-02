class TreasuryTransaction {
  final String id;
  final String type; // 'expense', 'transfer', 'deposit'
  final String source; // 'cash', 'bank', 'personal'
  final String? destination; // 'bank', 'cash'
  final double amount;
  final String date;
  final String time;
  final String description;
  final String category;
  final String? referenceCode;
  final String? impactOnLiquidity; // 'none', 'inject', 'deduct'
  final int createdAt;

  TreasuryTransaction({
    required this.id,
    required this.type,
    required this.source,
    this.destination,
    required this.amount,
    required this.date,
    required this.time,
    required this.description,
    required this.category,
    this.referenceCode,
    this.impactOnLiquidity = 'deduct',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'source': source,
    if (destination != null) 'destination': destination,
    'amount': amount,
    'date': date,
    'time': time,
    'description': description,
    'category': category,
    if (referenceCode != null) 'referenceCode': referenceCode,
    if (impactOnLiquidity != null) 'impactOnLiquidity': impactOnLiquidity,
    'createdAt': createdAt,
  };

  factory TreasuryTransaction.fromJson(Map<String, dynamic> json) => TreasuryTransaction(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? 'expense',
    source: json['source']?.toString() ?? 'bank',
    destination: json['destination']?.toString(),
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    date: json['date']?.toString() ?? '',
    time: json['time']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    category: json['category']?.toString() ?? 'عمومی',
    referenceCode: json['referenceCode']?.toString(),
    impactOnLiquidity: json['impactOnLiquidity']?.toString() ?? 'deduct',
    createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
  );
}

class ActivityLog {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final int timestamp;
  final String type; // 'invoice', 'product', 'customer', 'payment', 'system', 'warning', 'export', 'backup'
  final String? tabTarget;

  ActivityLog({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.timestamp,
    required this.type,
    this.tabTarget,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'time': time,
    'timestamp': timestamp,
    'type': type,
    if (tabTarget != null) 'tabTarget': tabTarget,
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    time: json['time']?.toString() ?? '',
    timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    type: json['type']?.toString() ?? 'system',
    tabTarget: json['tabTarget']?.toString(),
  );
}
