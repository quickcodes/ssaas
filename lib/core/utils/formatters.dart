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

  /// Natural alphanumeric string comparison for sorting names like "Table 1", "Table 2", "Table 10".
  static int naturalCompare(String a, String b) {
    final regex = RegExp(r'(\d+|\D+)');
    final matchesA = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = regex.allMatches(b).map((m) => m.group(0)!).toList();

    final minLength =
        matchesA.length < matchesB.length ? matchesA.length : matchesB.length;
    for (int i = 0; i < minLength; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];

      final numA = BigInt.tryParse(partA);
      final numB = BigInt.tryParse(partB);

      if (numA != null && numB != null) {
        final diff = numA.compareTo(numB);
        if (diff != 0) return diff;
      } else {
        final diff = partA.toLowerCase().compareTo(partB.toLowerCase());
        if (diff != 0) return diff;
      }
    }

    final lengthDiff = matchesA.length.compareTo(matchesB.length);
    if (lengthDiff != 0) return lengthDiff;
    return a.compareTo(b);
  }
}
