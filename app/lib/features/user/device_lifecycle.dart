import 'dart:math';

import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class DeviceLifecycle {
  Future<void> registerCurrentDevice();
  Future<void> logoutCurrentDevice();
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
    this.appVersion = '1.0.0',
    int Function()? platformProvider,
  }) : platformProvider = platformProvider ?? _defaultPlatform;

  final PrivacyRepository repository;
  final DeviceIdentityStore identityStore;
  final String appVersion;
  final int Function() platformProvider;

  @override
  Future<void> registerCurrentDevice() async {
    final deviceUid = await identityStore.getOrCreateDeviceUid();
    await repository.registerDevice(
      deviceUid: deviceUid,
      platform: platformProvider(),
      appVersion: appVersion,
    );
  }

  @override
  Future<void> logoutCurrentDevice() async {
    final deviceUid = await identityStore.getOrCreateDeviceUid();
    final devices = await repository.loadDevices();
    for (final device in devices) {
      if (device.deviceUid == deviceUid && device.active) {
        await repository.logoutDevice(device.id);
        return;
      }
    }
  }

  static int _defaultPlatform() {
    if (kIsWeb) return 3;
    return defaultTargetPlatform == TargetPlatform.iOS ? 1 : 2;
  }
}
