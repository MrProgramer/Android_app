import 'package:intl/intl.dart';

class PersianFormatter {
  static const List<String> _latinDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  static const List<String> _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// Convert any string or number to Persian digits
  static String toPersianDigits(dynamic input) {
    if (input == null) return '';
    String str = input.toString();
    for (int i = 0; i < 10; i++) {
      str = str.replaceAll(_latinDigits[i], _persianDigits[i]);
    }
    return str;
  }

  /// Format price with 3-digit comma separators and optional "تومان"
  static String formatPrice(num? amount, {bool includeUnit = true, bool isPersianDigits = true}) {
    if (amount == null) return isPersianDigits ? '۰' : '0';
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(amount.round());
    final result = isPersianDigits ? toPersianDigits(formatted) : formatted;
    return includeUnit ? '$result تومان' : result;
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

  /// Clean user input string to valid double or integer
  static double parseDouble(String input) {
    String clean = input.trim();
    for (int i = 0; i < 10; i++) {
      clean = clean.replaceAll(_persianDigits[i], _latinDigits[i]);
    }
    clean = clean.replaceAll(',', '').replaceAll('،', '');
    return double.tryParse(clean) ?? 0.0;
  }

  static int parseInt(String input) {
    return parseDouble(input).round();
  }
}
