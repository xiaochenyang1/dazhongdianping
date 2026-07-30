import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeCircleError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '查看我的圈子需要登录': strings.circleErrorJoinedOnlyLoginRequired,
      '圈子不存在': strings.circleErrorNotFound,
      ...overrides,
    },
  );
}
