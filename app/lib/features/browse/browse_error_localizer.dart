import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeBrowseError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '商户不存在': strings.browseErrorShopNotFound,
      '门店不存在': strings.browseErrorShopNotFound,
      'sort 仅支持 latest、popular 或 score':
          strings.browseErrorUnsupportedReviewSort,
      '搜索历史不存在': strings.browseErrorSearchHistoryNotFound,
      'shopId 无效': strings.browseErrorInvalidShopId,
      'targetType 只支持 1店铺 2帖子': strings.browseErrorUnsupportedFavoriteTarget,
      ...overrides,
    },
  );
}
