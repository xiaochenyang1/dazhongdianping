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

  String unavailableReason(ThirdPartyFeature feature) => switch (feature) {
    ThirdPartyFeature.maps =>
      googleMapsEnabled ? '' : 'Google Maps 未配置，仍可按城市和列表浏览。',
    ThirdPartyFeature.payment =>
      (stripeEnabled || paypalEnabled) ? '' : '真实支付未配置，客户端不会伪造支付成功。',
    ThirdPartyFeature.push => pushEnabled ? '' : 'FCM/APNs 未配置，通知仍可通过站内消息补偿。',
  };
}
