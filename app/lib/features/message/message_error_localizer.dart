import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeMessageError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '用户不存在': strings.messageErrorUserNotFound,
      '会话不存在': strings.messageErrorConversationMissing,
      '不能给自己发送私信': strings.messageErrorCannotMessageSelf,
      '双方存在拉黑关系，无法发送私信': strings.messageErrorBlockedRelationship,
      '不能拉黑自己': strings.messageErrorCannotBlockSelf,
      '举报目标不存在或无权访问': strings.messageErrorReportTargetUnavailable,
      '请勿重复举报': strings.messageErrorReportDuplicate,
      ...overrides,
    },
  );
}
