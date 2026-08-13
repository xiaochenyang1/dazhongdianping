import 'package:dazhongdianping_app/core/app_localizations.dart';

enum ThirdPartyFeature { maps, payment, push }

class ThirdPartyConfig {
  const ThirdPartyConfig({
    this.googleMapsApiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    this.stripePublishableKey = const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
    ),
    this.paypalClientId = const String.fromEnvironment('PAYPAL_CLIENT_ID'),
    this.firebaseConfigured = const bool.fromEnvironment('FIREBASE_CONFIGURED'),
    this.shareBaseUrl = const String.fromEnvironment(
      'SHARE_BASE_URL',
      defaultValue: 'https://local.life',
    ),
  });

  final String googleMapsApiKey;
  final String stripePublishableKey;
  final String paypalClientId;
  final bool firebaseConfigured;
  final String shareBaseUrl;

  bool get googleMapsEnabled => googleMapsApiKey.trim().isNotEmpty;
  bool get stripeEnabled => stripePublishableKey.trim().isNotEmpty;
  bool get paypalEnabled => paypalClientId.trim().isNotEmpty;
  bool get pushEnabled => firebaseConfigured;

  /// Normalized origin used to build share links. Strips any trailing slash so
  /// `https://local.life/` and `https://local.life` both yield the same path.
  /// Returns the compile-time [shareBaseUrl] (the `local.life` placeholder by
  /// default) so the share button is never dead in dev — production builds
  /// override it via the `SHARE_BASE_URL` dart-define.
  String get normalizedShareBaseUrl {
    final trimmed = shareBaseUrl.trim();
    return trimmed.isEmpty ? 'https://local.life' : trimmed.replaceAll(
      RegExp(r'/+$'),
      '',
    );
  }

  /// Builds the canonical deep link for a shop detail page.
  String shopShareUrl(int shopId) => '$normalizedShareBaseUrl/shops/$shopId';

  String unavailableReason(
    AppLocalizations strings,
    ThirdPartyFeature feature,
  ) => switch (feature) {
    ThirdPartyFeature.maps => googleMapsEnabled ? '' : strings.mapsUnavailable,
    ThirdPartyFeature.payment =>
      (stripeEnabled || paypalEnabled) ? '' : strings.realPaymentUnavailable,
    ThirdPartyFeature.push => pushEnabled ? '' : strings.pushUnavailable,
  };
}
