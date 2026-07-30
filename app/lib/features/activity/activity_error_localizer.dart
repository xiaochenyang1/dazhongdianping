import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/browse/browse_error_localizer.dart';
import 'package:dazhongdianping_app/features/community/community_error_localizer.dart';
import 'package:dazhongdianping_app/features/rank/rank_error_localizer.dart';
import 'package:dazhongdianping_app/features/topic/topic_error_localizer.dart';
import 'package:dazhongdianping_app/features/trade/trade_error_localizer.dart';

String localizeActivityError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '活动不存在或未上线': strings.activityErrorNotFoundOrOffline,
      ...overrides,
    },
  );
}

String localizeActivityTargetError(
  AppLocalizations strings,
  ActivityItem item,
  Object error,
) {
  return switch (item.targetType) {
    1 => localizeBrowseError(strings, error),
    2 => localizeTradeError(strings, error),
    3 => localizeCommunityError(strings, error),
    4 => localizeRankError(strings, error),
    5 => localizeTopicError(strings, error),
    _ => localizeActivityError(strings, error),
  };
}
