import 'package:intl/intl.dart';

String formatMoney(num amount, String currency, {String locale = 'en_GB'}) {
  return NumberFormat.simpleCurrency(
    locale: locale,
    name: currency,
  ).format(amount);
}

String formatLocalDateTime(
  DateTime value, {
  required String timezoneLabel,
  String locale = 'en_GB',
}) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)} $timezoneLabel';
}
