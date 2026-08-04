import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

abstract interface class PushTokenService {
  /// Returns the push token for the current device, or null if not available.
  Future<String?> getPushToken();

  /// Returns the server channel: 1 = FCM, 2 = APNs, 0 = unavailable.
  Future<int> getPushChannel();

  /// Emits a new token whenever the provider rotates it. Listeners are
  /// responsible for pushing the value back to the server.
  Stream<String> get onTokenRefresh;
}

class NoOpPushTokenService implements PushTokenService {
  @override
  Future<String?> getPushToken() async => null;

  @override
  Future<int> getPushChannel() async => 0;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}

class PushTokenServiceFactory {
  static PushTokenService create(ThirdPartyConfig config) {
    if (!config.pushEnabled) {
      return NoOpPushTokenService();
    }

    if (kIsWeb) {
      return NoOpPushTokenService(); // Web push handled separately if needed
    }

    return _FirebasePushTokenService();
  }
}

class _FirebasePushTokenService implements PushTokenService {
  static const String _channelName = 'Firebase';
  FirebaseMessaging? _messaging;

  @override
  Future<int> getPushChannel() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 2;
    }
    return 1;
  }

  @override
  Future<String?> getPushToken() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = _messaging ??= FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return messaging.getAPNSToken();
        }
        return messaging.getToken();
      }
      return null;
    } catch (e) {
      debugPrint('$_channelName token error: $e');
      return null;
    }
  }

  /// Firebase only emits on this stream once the app is initialized, and it
  /// throws synchronously when the native config is missing — swallow that so
  /// a missing google-services.json degrades to "no push" instead of crashing
  /// every listener.
  @override
  Stream<String> get onTokenRefresh {
    try {
      if (Firebase.apps.isEmpty) {
        return const Stream<String>.empty();
      }
      final messaging = _messaging ??= FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return messaging.onTokenRefresh
            .asyncMap((_) async => await messaging.getAPNSToken() ?? '')
            .where((token) => token.isNotEmpty);
      }
      return messaging.onTokenRefresh;
    } catch (e) {
      debugPrint('$_channelName token refresh unavailable: $e');
      return const Stream<String>.empty();
    }
  }
}
