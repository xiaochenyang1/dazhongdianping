import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/review/review_error_localizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps risk block messageKey to the friendly copy in every language', () {
    const error = ApiException(
      '点评被风控拦截：相似度过高',
      statusCode: 403,
      messageKey: 'riskcontrol.review_blocked',
    );

    for (final tag in ['zh-CN', 'zh-TW', 'en']) {
      final strings = AppLocalizations.forTag(tag);
      expect(localizeReviewError(strings, error), strings.reviewErrorRiskBlocked);
    }
  });

  test('falls back to normal review localization without the risk key', () {
    final strings = AppLocalizations.forTag('zh-CN');
    const error = ApiException('点评不存在', statusCode: 404);
    expect(localizeReviewError(strings, error), strings.reviewErrorNotFound);
  });
}
