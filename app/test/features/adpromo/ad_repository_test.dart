import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/adpromo/ad_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class AdFakeApi implements JsonApi {
  AdFakeApi({this.getResponse = const {}});

  Map<String, dynamic> getResponse;
  String? getPath;
  Map<String, Object?>? getQuery;
  String? postPath;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, Object?>? query}) async {
    getPath = path;
    getQuery = query;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    return const {'charged': true};
  }
}

void main() {
  test('loadAdSlots passes slotType/keyword and parses ad shops', () async {
    final api = AdFakeApi(getResponse: {
      'value': [
        {'campaignId': 8001, 'shopId': 10001, 'shopName': '沪上渝里', 'coverUrl': 'x.jpg', 'score': 4.6, 'ad': true},
      ],
    });
    final repository = AdRepository(api);

    final slots = await repository.loadAdSlots(slotType: 1, keyword: '火锅', limit: 3);

    expect(api.getPath, '/api/c/v1/ads');
    expect(api.getQuery?['slotType'], 1);
    expect(api.getQuery?['keyword'], '火锅');
    expect(api.getQuery?['limit'], 3);
    expect(slots.single.campaignId, 8001);
    expect(slots.single.shopName, '沪上渝里');
  });

  test('loadAdSlots omits keyword when empty', () async {
    final api = AdFakeApi(getResponse: {'value': const []});
    final repository = AdRepository(api);

    await repository.loadAdSlots(slotType: 2);

    expect(api.getQuery?.containsKey('keyword'), false);
  });

  test('reportClick posts to the billing endpoint', () async {
    final api = AdFakeApi();
    final repository = AdRepository(api);

    await repository.reportClick(8001);

    expect(api.postPath, '/api/c/v1/ads/8001/click');
  });
}
