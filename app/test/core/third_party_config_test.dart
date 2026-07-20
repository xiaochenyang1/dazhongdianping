import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('third-party features stay disabled without real configuration', () {
    const config = ThirdPartyConfig();
    expect(config.googleMapsEnabled, isFalse);
    expect(config.stripeEnabled, isFalse);
    expect(config.pushEnabled, isFalse);
    expect(
      config.unavailableReason(ThirdPartyFeature.payment),
      contains('未配置'),
    );
  });
}
