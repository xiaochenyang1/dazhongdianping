import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:dazhongdianping_app/core/launch_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

class LaunchApi implements JsonApi {
  LaunchApi(this.response);
  final Map<String, dynamic> response;
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => response;
  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};
}

void main() {
  test('a stale CN configuration cannot enable EU features', () async {
    final available = await LaunchCapabilities.load(
      LaunchApi({
        'region': 'CN',
        'creatorRewards': true,
        'seckill': true,
        'groupBuy': true,
      }),
      region: AppRegion.eu,
    );
    expect(available.creatorRewards, isFalse);
    expect(available.seckill, isFalse);
    expect(available.groupBuy, isFalse);
  });

  test(
    'only explicit booleans enable features and missing fields stay disabled',
    () async {
      final available = await LaunchCapabilities.load(
        LaunchApi({'region': 'EU', 'creatorRewards': 'true', 'seckill': true}),
        region: AppRegion.eu,
      );
      expect(available.creatorRewards, isFalse);
      expect(available.seckill, isTrue);
      expect(available.groupBuy, isFalse);
    },
  );
}
