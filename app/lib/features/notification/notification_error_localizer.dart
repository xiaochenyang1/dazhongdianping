import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeNotificationError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '网络暂时不可用': strings.notificationErrorUnavailable,
      '刷新网络暂时不可用': strings.notificationErrorRefreshUnavailable,
      ...overrides,
    },
  );
}
