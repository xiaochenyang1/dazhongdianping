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
      '关联门店不存在或不可用': strings.postShopUnavailable,
      '关联团购不存在、不可用或不属于所选门店': strings.postDealUnavailable,
      '你已经举报过这条帖子了': strings.communityErrorReportDuplicate,
      '评论不存在': strings.commentErrorUnavailable,
      '评论不存在或无权删除': strings.commentErrorUnavailable,
      '你已经举报过这条评论了': strings.commentErrorReportDuplicate,
      '回复目标不存在': strings.communityErrorReplyTargetMissing,
      '请先加入圈子再发帖': strings.communityErrorJoinCircleToPost,
      ...overrides,
    },
  );
}
