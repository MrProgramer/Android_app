class StoreSettings {
  final String brandName;
  final String? storeNameFa;
  final String subtitle;
  final String bismillah;
  final String phone;
  final String address;
  final String bankName;
  final String accountNumber;
  final String cardNumber;
  final String iban;
  final String minOrderNotice;
  final String sellerStampName;
  final String themeColor;
  final String designMode;
  final String numberFormat; // 'persian' or 'latin'
  final bool enableWatermark;
  final String watermarkText;
  final bool showSignatureArea;
  final String? adminPin;
  final bool enableBiometrics;
  final bool requireAuthForInvoiceActions;
  final bool hideConfidentialPrices;
  final bool defaultShowCoverPrice;
  final bool enableAutoBackup;
  final int autoBackupIntervalHours;
  final int backupRetentionCount;
  final int? lastAutoBackupTimestamp;
  final String? lastBackupDateFormatted;

  StoreSettings({
    this.brandName = 'بازرگانی',
    this.storeNameFa,
    this.subtitle = 'فاکتور فروش کالا و خدمات',
    this.bismillah = 'هوالرزاق',
    this.phone = '09120000000',
    this.address = 'دفتر مرکزی بازرگانی و انبار',
    this.bankName = 'بانک ملت',
    this.accountNumber = '',
    this.cardNumber = '',
    this.iban = '',
    this.minOrderNotice = '',
    this.sellerStampName = 'مدیریت بازرگانی',
    this.themeColor = 'black',
    this.designMode = 'modern',
    this.numberFormat = 'persian',
    this.enableWatermark = true,
    this.watermarkText = 'بازرگانی',
    this.showSignatureArea = true,
    this.adminPin = '1234',
    this.enableBiometrics = true,
    this.requireAuthForInvoiceActions = true,
    this.hideConfidentialPrices = false,
    this.defaultShowCoverPrice = true,
    this.enableAutoBackup = true,
    this.autoBackupIntervalHours = 24,
    this.backupRetentionCount = 5,
    this.lastAutoBackupTimestamp,
    this.lastBackupDateFormatted,
  });

  Map<String, dynamic> toJson() => {
    'brandName': brandName,
    if (storeNameFa != null) 'storeNameFa': storeNameFa,
    'subtitle': subtitle,
    'bismillah': bismillah,
    'phone': phone,
    'address': address,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'cardNumber': cardNumber,
    'iban': iban,
    'minOrderNotice': minOrderNotice,
    'sellerStampName': sellerStampName,
    'themeColor': themeColor,
    'designMode': designMode,
    'numberFormat': numberFormat,
    'enableWatermark': enableWatermark,
    'watermarkText': watermarkText,
    'showSignatureArea': showSignatureArea,
    if (adminPin != null) 'adminPin': adminPin,
    'enableBiometrics': enableBiometrics,
    'requireAuthForInvoiceActions': requireAuthForInvoiceActions,
    'hideConfidentialPrices': hideConfidentialPrices,
    'defaultShowCoverPrice': defaultShowCoverPrice,
    'enableAutoBackup': enableAutoBackup,
    'autoBackupIntervalHours': autoBackupIntervalHours,
    'backupRetentionCount': backupRetentionCount,
    if (lastAutoBackupTimestamp != null) 'lastAutoBackupTimestamp': lastAutoBackupTimestamp,
    if (lastBackupDateFormatted != null) 'lastBackupDateFormatted': lastBackupDateFormatted,
  };

  factory StoreSettings.fromJson(Map<String, dynamic> json) => StoreSettings(
    brandName: json['brandName']?.toString() ?? 'بازرگانی',
    storeNameFa: json['storeNameFa']?.toString(),
    subtitle: json['subtitle']?.toString() ?? 'فاکتور فروش کالا و خدمات',
    bismillah: json['bismillah']?.toString() ?? 'هوالرزاق',
    phone: json['phone']?.toString() ?? '09120000000',
    address: json['address']?.toString() ?? 'دفتر مرکزی بازرگانی و انبار',
    bankName: json['bankName']?.toString() ?? 'بانک ملت',
    accountNumber: json['accountNumber']?.toString() ?? '',
    cardNumber: json['cardNumber']?.toString() ?? '',
    iban: json['iban']?.toString() ?? '',
    minOrderNotice: json['minOrderNotice']?.toString() ?? '',
    sellerStampName: json['sellerStampName']?.toString() ?? 'مدیریت بازرگانی',
    themeColor: json['themeColor']?.toString() ?? 'black',
    designMode: json['designMode']?.toString() ?? 'modern',
    numberFormat: json['numberFormat']?.toString() ?? 'persian',
    enableWatermark: json['enableWatermark'] != false,
    watermarkText: json['watermarkText']?.toString() ?? 'بازرگانی',
    showSignatureArea: json['showSignatureArea'] != false,
    adminPin: json['adminPin']?.toString() ?? '1234',
    enableBiometrics: json['enableBiometrics'] != false,
    requireAuthForInvoiceActions: json['requireAuthForInvoiceActions'] != false,
    hideConfidentialPrices: json['hideConfidentialPrices'] == true,
    defaultShowCoverPrice: json['defaultShowCoverPrice'] != false,
    enableAutoBackup: json['enableAutoBackup'] != false,
    autoBackupIntervalHours: (json['autoBackupIntervalHours'] as num?)?.toInt() ?? 24,
    backupRetentionCount: (json['backupRetentionCount'] as num?)?.toInt() ?? 5,
    lastAutoBackupTimestamp: (json['lastAutoBackupTimestamp'] as num?)?.toInt(),
    lastBackupDateFormatted: json['lastBackupDateFormatted']?.toString(),
  );
}
