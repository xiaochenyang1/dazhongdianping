import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';

String localizeAuthError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  if (error is! ApiException) {
    return '$error';
  }

  final message = error.message.trim();
  final localized =
      overrides[message] ??
      _localizedAuthErrorByKey(strings, error.messageKey) ??
      _localizedAuthErrorByMessage(strings, message);
  if (localized == null) {
    return '$error';
  }
  return error.traceId == null
      ? localized
      : '$localized [traceId: ${error.traceId}]';
}

String? _localizedAuthErrorByKey(AppLocalizations strings, String? messageKey) {
  return switch (messageKey) {
    'auth.user_banned' => strings.authErrorAccountBanned,
    _ => null,
  };
}

String? _localizedAuthErrorByMessage(AppLocalizations strings, String message) {
  return switch (message) {
    '账号或密码错误' => strings.authErrorInvalidCredentials,
    '账号已被封禁，暂时无法登录' => strings.authErrorAccountBanned,
    '账号已注册' => strings.authErrorAccountRegistered,
    '账号不存在' => strings.authErrorAccountNotFound,
    '验证码无效或已过期' => strings.authErrorCodeInvalid,
    '邮箱格式不合法' => strings.authErrorInvalidEmail,
    '手机号格式不合法' => strings.authErrorInvalidPhone,
    '验证码发送太频繁，请稍后再试' => strings.authErrorCodeRateLimited,
    '验证码发送通道尚未配置' => strings.authErrorCodeSendUnavailable,
    '验证码校验通道尚未配置' => strings.authErrorCodeVerifyUnavailable,
    '该邮箱已被其他账号绑定' => strings.authErrorEmailAlreadyBound,
    '该手机号已被其他账号绑定' => strings.authErrorPhoneAlreadyBound,
    '旧密码不正确' => strings.authErrorOldPasswordIncorrect,
    '新密码不能和旧密码一样' => strings.authErrorSamePasswordAsOld,
    '用户不存在' => strings.authErrorCurrentUserNotFound,
    '用户登录状态不存在' => strings.authErrorSessionMissing,
    'nickname 不能超过 64 字' => strings.authErrorProfileNicknameTooLong,
    'avatar 不能超过 255 字' => strings.authErrorProfileAvatarTooLong,
    'signature 不能超过 255 字' => strings.authErrorProfileSignatureTooLong,
    '用户资料更新失败' => strings.authErrorProfileUpdateFailed,
    _ => null,
  };
}
