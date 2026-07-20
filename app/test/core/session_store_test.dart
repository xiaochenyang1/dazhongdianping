import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session store persists and clears access/refresh tokens', () async {
    final store = MemorySessionStore();
    await store.save(accessToken: 'access-1', refreshToken: 'refresh-1');

    expect(await store.readAccessToken(), 'access-1');
    expect(await store.readRefreshToken(), 'refresh-1');

    await store.clear();
    expect(await store.readAccessToken(), isNull);
    expect(await store.readRefreshToken(), isNull);
  });
}
