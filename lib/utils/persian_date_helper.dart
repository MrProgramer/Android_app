import 'package:shamsi_date/shamsi_date.dart';
import 'persian_number_formatter.dart';

class PersianDateHelper {
  /// Return current Jalali date string e.g. "1405/08/11"
  static String getCurrentJalaliDate() {
    final now = Jalali.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  /// Return current time string e.g. "14:35"
  static String getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Return readable date e.g. "دوشنبه، ۱۱ آبان ۱۴۰۵"
  static String getReadableJalaliDate() {
    final now = Jalali.now();
    final weekDay = now.formatter.wN;
    final day = PersianFormatter.toPersianDigits(now.day);
    final monthName = now.formatter.mN;
    final year = PersianFormatter.toPersianDigits(now.year);
    return '$weekDay، $day $monthName $year';
  }
}
