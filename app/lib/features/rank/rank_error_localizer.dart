import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeRankError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '榜单不存在': strings.rankErrorNotFound,
      'type 只支持 1必吃榜 2好评榜 3热门榜': strings.rankErrorInvalidType,
      ...overrides,
    },
  );
}
