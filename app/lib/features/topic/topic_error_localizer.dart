import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeTopicError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '话题不存在': strings.topicErrorNotFound,
      '话题不可用': strings.topicErrorUnavailable,
      '关注失败': strings.topicErrorFollowFailed,
      ...overrides,
    },
  );
}
