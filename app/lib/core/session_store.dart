import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clear();
}

class MemorySessionStore implements SessionStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const _accessKey = 'dzdp_access_token';
  static const _refreshKey = 'dzdp_refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) => Future.wait([
    _storage.write(key: _accessKey, value: accessToken),
    _storage.write(key: _refreshKey, value: refreshToken),
  ]);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> clear() => Future.wait([
    _storage.delete(key: _accessKey),
    _storage.delete(key: _refreshKey),
  ]);
}
