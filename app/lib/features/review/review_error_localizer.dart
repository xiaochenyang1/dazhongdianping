import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeReviewError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  // 风控拦截：后端消息含动态命中原因，改用 messageKey 匹配统一友好文案
  if (error is ApiException && error.messageKey == 'riskcontrol.review_blocked') {
    return strings.reviewErrorRiskBlocked;
  }
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '点评不存在': strings.reviewErrorNotFound,
      '你已经举报过这条点评了': strings.reviewErrorReportDuplicate,
      '评论不存在': strings.commentErrorUnavailable,
      '评论不存在或无权删除': strings.commentErrorUnavailable,
      '你已经举报过这条评论了': strings.commentErrorReportDuplicate,
      '回复目标不存在': strings.reviewErrorReplyTargetMissing,
      '用户状态不可用': strings.reviewErrorUserUnavailable,
      '门店不存在或不可点评': strings.reviewErrorShopUnavailable,
      '点评所属门店不可修改': strings.reviewErrorShopImmutable,
      ...overrides,
    },
  );
}
