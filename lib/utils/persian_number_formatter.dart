import 'package:intl/intl.dart';

enum TimePeriodFilter {
  today,
  week,
  month,
  threeMonths,
  oneYear,
  all;

  String get labelFa {
    switch (this) {
      case TimePeriodFilter.today:
        return 'امروز';
      case TimePeriodFilter.week:
        return '۷ روز اخیر';
      case TimePeriodFilter.month:
        return 'این ماه';
      case TimePeriodFilter.threeMonths:
        return '۳ ماهه';
      case TimePeriodFilter.oneYear:
        return 'امسال';
      case TimePeriodFilter.all:
        return 'کل دوره';
    }
  }
}

class PersianFormatter {
  static const List<String> _latinDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  static const List<String> _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  static const List<String> _ones = ['', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه'];
  static const List<String> _teens = [
    'ده', 'یازده', 'دوازده', 'سیزده', 'چهارده', 'پانزده', 'شانزده', 'هفده', 'هجده', 'نوزده'
  ];
  static const List<String> _tens = [
    '', '', 'بیست', 'سی', 'چهل', 'پنجاه', 'شصت', 'هفتاد', 'هشتاد', 'نود'
  ];
  static const List<String> _hundreds = [
    '', 'یکصد', 'دویست', 'سیصد', 'چهارصد', 'پانصد', 'ششصد', 'هفتصد', 'هشتصد', 'نهصد'
  ];
  static const List<String> _thousands = ['', 'هزار', 'میلیون', 'میلیارد', 'تریلیون'];

  /// Convert any string or number to Persian digits
  static String toPersianDigits(dynamic input) {
    if (input == null) return '';
    String str = input.toString();
    for (int i = 0; i < 10; i++) {
      str = str.replaceAll(_latinDigits[i], _persianDigits[i]);
    }
    return str;
  }

  /// Convert Persian digits to Latin digits
  static String toEnglishDigits(dynamic input) {
    if (input == null) return '';
    String str = input.toString();
    for (int i = 0; i < 10; i++) {
      str = str.replaceAll(_persianDigits[i], _latinDigits[i]);
    }
    return str.replaceAll('،', '').replaceAll(',', '').trim();
  }

  /// Format price with 3-digit comma separators and optional "تومان"
  static String formatPrice(num? amount, {bool includeUnit = true, bool isPersianDigits = true}) {
    if (amount == null) return isPersianDigits ? (includeUnit ? '۰ تومان' : '۰') : (includeUnit ? '0 تومان' : '0');
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(amount.round());
    final result = isPersianDigits ? toPersianDigits(formatted) : formatted;
    return includeUnit ? '$result تومان' : result;
  }

  /// Mask confidential prices in Secret Mode
  static String formatSecretPrice(num? amount, bool isSecret, {bool includeUnit = true}) {
    if (isSecret) return '***';
    return formatPrice(amount, includeUnit: includeUnit);
  }

  /// Calculate human-readable magnitude scale (میلیارد / میلیون / هزار)
  /// e.g. 14,800,000 -> "۱۴٫۸ میلیون تومان"
  static String formatAmountScale(num? numVal) {
    if (numVal == null || numVal == 0) return '۰ تومان';
    final absVal = numVal.abs();
    final sign = numVal < 0 ? 'منفی ' : '';

    if (absVal >= 1000000000) {
      final billions = absVal / 1000000000;
      final formatted = (billions).toStringAsFixed(1).replaceAll('.', '٫');
      return '$sign${toPersianDigits(formatted)} میلیارد تومان';
    }
    if (absVal >= 1000000) {
      final millions = absVal / 1000000;
      final formatted = (millions).toStringAsFixed(1).replaceAll('.', '٫');
      return '$sign${toPersianDigits(formatted)} میلیون تومان';
    }
    if (absVal >= 1000) {
      final thousands = absVal / 1000;
      final formatted = (thousands).toStringAsFixed(0);
      return '$sign${toPersianDigits(formatted)} هزار تومان';
    }
    return '$sign${toPersianDigits(absVal.round())} تومان';
  }

  /// Format breakdown of stock (cartons and extra pieces)
  static String formatStockBreakdown(int totalPieces, int piecesPerCarton, {String unitTitle = 'عدد'}) {
    if (piecesPerCarton <= 1) {
      return '${toPersianDigits(totalPieces)} $unitTitle';
    }
    final cartons = totalPieces ~/ piecesPerCarton;
    final extra = totalPieces % piecesPerCarton;

    if (cartons > 0 && extra > 0) {
      return '${toPersianDigits(cartons)} کارتن و ${toPersianDigits(extra)} دانه';
    } else if (cartons > 0) {
      return '${toPersianDigits(cartons)} کارتن';
    } else {
      return '${toPersianDigits(extra)} $unitTitle';
    }
  }

  /// Convert numbers to verbal Persian words (e.g. 5800 -> "پنج هزار و هشتصد تومان")
  static String numberToPersianWords(num? numVal, {bool includeCurrency = true}) {
    if (numVal == null || numVal == 0) return includeCurrency ? 'صفر تومان' : 'صفر';
    if (numVal < 0) return 'منفی ${numberToPersianWords(numVal.abs(), includeCurrency: includeCurrency)}';

    String processGroup(int n) {
      final parts = <String>[];
      final h = n ~/ 100;
      final t = (n % 100) ~/ 10;
      final o = n % 10;

      if (h > 0) parts.add(_hundreds[h]);
      if (t == 1) {
        parts.add(_teens[o]);
      } else {
        if (t > 1) parts.add(_tens[t]);
        if (o > 0) parts.add(_ones[o]);
      }
      return parts.join(' و ');
    }

    final groups = <String>[];
    int groupIndex = 0;
    int remaining = numVal.round();

    while (remaining > 0) {
      final group = remaining % 1000;
      if (group > 0) {
        final groupWords = processGroup(group);
        final suffix = _thousands[groupIndex];
        groups.insert(0, suffix.isNotEmpty ? '$groupWords $suffix' : groupWords);
      }
      remaining = remaining ~/ 1000;
      groupIndex++;
    }

    final words = groups.join(' و ');
    return includeCurrency ? '$words تومان' : words;
  }

  /// Check if a Jalali date string "1405/08/11" is within the selected period
  static bool isDateInPeriod(String? dateStr, TimePeriodFilter period, {String? todayStr}) {
    if (dateStr == null || dateStr.trim().isEmpty || period == TimePeriodFilter.all) {
      return true;
    }

    final parts = dateStr.split('/').map((s) => int.tryParse(toEnglishDigits(s)) ?? 0).toList();
    if (parts.length != 3) return true;

    final todayParts = (todayStr ?? '1405/08/11')
        .split('/')
        .map((s) => int.tryParse(toEnglishDigits(s)) ?? 0)
        .toList();
    if (todayParts.length != 3) return true;

    if (period == TimePeriodFilter.today) {
      return parts[0] == todayParts[0] && parts[1] == todayParts[1] && parts[2] == todayParts[2];
    }

    final todayDays = todayParts[0] * 365 + todayParts[1] * 30 + todayParts[2];
    final itemDays = parts[0] * 365 + parts[1] * 30 + parts[2];
    final diffDays = todayDays - itemDays;

    if (diffDays < -2) return false;

    switch (period) {
      case TimePeriodFilter.week:
        return diffDays <= 7;
      case TimePeriodFilter.month:
        return diffDays <= 30;
      case TimePeriodFilter.threeMonths:
        return diffDays <= 90;
      case TimePeriodFilter.oneYear:
        return diffDays <= 365;
      case TimePeriodFilter.today:
      case TimePeriodFilter.all:
        return true;
    }
  }

  /// Clean user input string to valid double or integer
  static double parseDouble(String input) {
    final clean = toEnglishDigits(input);
    return double.tryParse(clean) ?? 0.0;
  }

  static int parseInt(String input) {
    return parseDouble(input).round();
  }
}
