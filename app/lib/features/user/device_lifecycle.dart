import 'dart:async';
import 'dart:math';

import 'package:dazhongdianping_app/core/push_service.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class DeviceLifecycle {
  Future<void> registerCurrentDevice();
  Future<void> logoutCurrentDevice();

  /// Stops listening for push token rotation. Safe to call more than once.
  Future<void> dispose();
}
abstract interface class DeviceIdentityStore {
  Future<String> getOrCreateDeviceUid();
}

class MemoryDeviceIdentityStore implements DeviceIdentityStore {
  MemoryDeviceIdentityStore([this.deviceUid = 'test-device-uid']);

  String deviceUid;

  @override
  Future<String> getOrCreateDeviceUid() async => deviceUid;
}

class SecureDeviceIdentityStore implements DeviceIdentityStore {
  SecureDeviceIdentityStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _deviceUidKey = 'dzdp_device_uid';
  final FlutterSecureStorage _storage;

  @override
  Future<String> getOrCreateDeviceUid() async {
    final existing = await _storage.read(key: _deviceUidKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final uid = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    await _storage.write(key: _deviceUidKey, value: uid);
    return uid;
  }
}

class ApiDeviceLifecycle implements DeviceLifecycle {
  ApiDeviceLifecycle({
    required this.repository,
    required this.identityStore,
    required this.thirdPartyConfig,
    this.pushTokenService,
    this.appVersion = '1.0.0',
    int Function()? platformProvider,
  }) : platformProvider = platformProvider ?? _defaultPlatform;

  final PrivacyRepository repository;
  final DeviceIdentityStore identityStore;
  final ThirdPartyConfig thirdPartyConfig;
  final PushTokenService? pushTokenService;
  final String appVersion;
  final int Function() platformProvider;

  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  Future<void> registerCurrentDevice() async {
    final deviceUid = await identityStore.getOrCreateDeviceUid();
    int providerChannel = 0;
    int pushChannel = 0;
    String pushToken = '';

    if (thirdPartyConfig.pushEnabled && pushTokenService != null) {
      try {
        providerChannel = await pushTokenService!.getPushChannel();
        final token = await pushTokenService!.getPushToken();
        if (token != null && token.isNotEmpty) {
          pushChannel = providerChannel;
          pushToken = token;
        }
      } catch (_) {
        // Device registration still matters when native push is unavailable.
      }
    }

    final device = await repository.registerDevice(
      deviceUid: deviceUid,
      platform: platformProvider(),
      appVersion: appVersion,
      pushChannel: pushChannel,
      pushToken: pushToken,
    );

    await _listenForTokenRefresh(device.id, providerChannel);
  }

  /// The provider rotates tokens on reinstall, restore and periodic refresh.
  /// Without this the server keeps dispatching to a dead token forever.
  Future<void> _listenForTokenRefresh(int deviceId, int pushChannel) async {
    if (!thirdPartyConfig.pushEnabled ||
        pushTokenService == null ||
        pushChannel == 0) {
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = pushTokenService!.onTokenRefresh.listen(
      (token) async {
        if (token.isEmpty) return;
        try {
          await repository.updateDevicePushToken(
            deviceId: deviceId,
            pushChannel: pushChannel,
            pushToken: token,
            appVersion: appVersion,
          );
        } catch (_) {
          // A failed sync must not tear down the stream; the next rotation
          // or the next registerCurrentDevice() will retry.
        }
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> logoutCurrentDevice() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    final deviceUid = await identityStore.getOrCreateDeviceUid();
    final devices = await repository.loadDevices();
    for (final device in devices) {
      if (device.deviceUid == deviceUid && device.active) {
        await repository.logoutDevice(device.id);
        return;
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  static int _defaultPlatform() {
    if (kIsWeb) return 3;
    return defaultTargetPlatform == TargetPlatform.iOS ? 1 : 2;
  }
}
