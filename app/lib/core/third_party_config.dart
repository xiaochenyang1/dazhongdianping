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
  });

  final String googleMapsApiKey;
  final String stripePublishableKey;
  final String paypalClientId;
  final bool firebaseConfigured;

  bool get googleMapsEnabled => googleMapsApiKey.trim().isNotEmpty;
  bool get stripeEnabled => stripePublishableKey.trim().isNotEmpty;
  bool get paypalEnabled => paypalClientId.trim().isNotEmpty;
  bool get pushEnabled => firebaseConfigured;

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
