import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('third-party features stay disabled without real configuration', () {
    const config = ThirdPartyConfig();
    expect(config.googleMapsEnabled, isFalse);
    expect(config.stripeEnabled, isFalse);
    expect(config.pushEnabled, isFalse);
    expect(
      config.unavailableReason(
        AppLocalizations.forTag('zh-CN'),
        ThirdPartyFeature.payment,
      ),
      '真实支付未配置，客户端不会伪造支付成功。',
    );
    expect(
      config.unavailableReason(
        AppLocalizations.forTag('en'),
        ThirdPartyFeature.push,
      ),
      'FCM/APNs is not configured. Notifications can still fall back to in-app messages.',
    );
  });
}
