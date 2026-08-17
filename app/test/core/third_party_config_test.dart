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

  test(
    'builds Google Maps static and directions URLs from shop coordinates',
    () {
      const config = ThirdPartyConfig(googleMapsApiKey: 'AIza-test');

      final mapUri = config.googleMapsStaticUri(const [
        (latitude: 48.857, longitude: 2.356),
        (latitude: 51.5117, longitude: -0.1318),
      ]);
      final directionsUri = config.googleMapsDirectionsUri(
        address: '12 Rue du Temple, Paris',
        latitude: 48.857,
        longitude: 2.356,
      );

      expect(mapUri.host, 'maps.googleapis.com');
      expect(mapUri.queryParameters['key'], 'AIza-test');
      expect(mapUri.queryParameters['markers'], contains('48.857,2.356'));
      expect(directionsUri.host, 'www.google.com');
      expect(directionsUri.queryParameters['destination'], '48.857,2.356');
    },
  );

  test('enables interactive maps only after native configuration', () {
    expect(
      const ThirdPartyConfig(
        googleMapsApiKey: 'AIza-test',
      ).googleMapsInteractiveEnabled,
      isFalse,
    );
    expect(
      const ThirdPartyConfig(
        googleMapsApiKey: 'AIza-test',
        googleMapsNativeConfigured: true,
      ).googleMapsInteractiveEnabled,
      isTrue,
    );
    expect(
      const ThirdPartyConfig(
        googleMapsNativeConfigured: true,
      ).googleMapsInteractiveEnabled,
      isFalse,
    );
  });
}
