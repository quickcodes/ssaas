import 'package:flutter_test/flutter_test.dart';
import 'package:snooker/core/utils/formatters.dart';

void main() {
  group('AppFormatters.naturalCompare', () {
    test('sorts table names naturally with single and multi-digit numbers', () {
      final input = [
        'Table 10',
        'Table 2',
        'Table 1',
        'Table 20',
        'Table 11',
        'Table 3',
      ];

      input.sort(AppFormatters.naturalCompare);

      expect(input, [
        'Table 1',
        'Table 2',
        'Table 3',
        'Table 10',
        'Table 11',
        'Table 20',
      ]);
    });

    test('sorts mixed prefix names correctly', () {
      final input = [
        'VIP Table 2',
        'Table 2',
        'VIP Table 1',
        'Table 1',
      ];

      input.sort(AppFormatters.naturalCompare);

      expect(input, [
        'Table 1',
        'Table 2',
        'VIP Table 1',
        'VIP Table 2',
      ]);
    });
  });
}
