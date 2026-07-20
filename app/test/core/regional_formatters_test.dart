import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats EUR and GBP using requested locale', () {
    expect(formatMoney(12.5, 'EUR', locale: 'en_GB'), '€12.50');
    expect(formatMoney(20, 'GBP', locale: 'en_GB'), '£20.00');
  });

  test('formats local business time with timezone label', () {
    expect(
      formatLocalDateTime(DateTime.utc(2026, 7, 15, 8), timezoneLabel: 'BST'),
      contains('BST'),
    );
  });
}
