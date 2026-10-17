import 'package:intl/intl.dart';

String formatMoney(num amount, String currency, {String locale = 'en_GB'}) {
  return NumberFormat.simpleCurrency(
    locale: locale.replaceAll('-', '_'),
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

String formatDisplayDateTime(String raw, {String locale = 'en_GB'}) {
  final value = DateTime.tryParse(raw.trim());
  if (value == null) return raw;
  final local = value.toLocal();
  return '${_formatDisplayDate(local, locale)} ${_two(local.hour)}:${_two(local.minute)}';
}

String formatDisplayDate(String raw, {String locale = 'en_GB'}) {
  final value = DateTime.tryParse(raw.trim());
  if (value == null) return raw;
  return _formatDisplayDate(value.toLocal(), locale);
}

String _formatDisplayDate(DateTime value, String locale) {
  final normalized = locale.toLowerCase().replaceAll('_', '-');
  if (normalized.startsWith('zh')) {
    return '${value.year}/${value.month}/${value.day}';
  }
  return '${_two(value.day)}/${_two(value.month)}/${value.year}';
}

String _two(int value) => value.toString().padLeft(2, '0');

// The reservation API already supplies the shop's local wall time.
// Extract its calendar fields without converting through the device timezone.
String formatReservationDateTime(
  String raw, {
  required String timeZone,
  String locale = 'en_GB',
}) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})',
  ).firstMatch(raw.trim());
  if (match == null) return raw;
  final date = DateTime.utc(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  final label = '${_formatDisplayDate(date, locale)} ${match[4]}:${match[5]}';
  return timeZone.isEmpty ? label : '$label $timeZone';
}
