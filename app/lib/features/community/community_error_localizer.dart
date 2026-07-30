import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeCommunityError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '帖子不存在': strings.communityErrorPostNotFound,
      '你已经举报过这条帖子了': strings.communityErrorReportDuplicate,
      '回复目标不存在': strings.communityErrorReplyTargetMissing,
      '请先加入圈子再发帖': strings.communityErrorJoinCircleToPost,
      ...overrides,
    },
  );
}
