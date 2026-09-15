import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormat = DateFormat('hh:mm a');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    return '$hStr:$mStr:$sStr';
  }

  static String dateTime(DateTime dt) {
    return _dateFormat.format(dt);
  }

  static String timeOnly(DateTime dt) {
    return _timeFormat.format(dt);
  }
}
