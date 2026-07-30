import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class RankFakeApi implements JsonApi {
  String? path;
  Map<String, Object?>? query;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (path == '/api/c/v1/ranks') {
      return {
        'value': [
          {
            'id': 30001,
            'name': '上海必吃榜',
            'type': 1,
            'typeText': '必吃榜',
            'cityName': '上海',
            'categoryName': '火锅',
            'period': '2026-07',
            'itemCount': 10,
            'topShopName': '渝里火锅徐汇店',
            'updatedAt': '2026-07-20 10:00:00',
          },
        ],
      };
    }
    if (path == '/api/c/v1/ranks/30001') {
      return {
        'id': 30001,
        'name': '上海必吃榜',
        'type': 1,
        'typeText': '必吃榜',
        'cityName': '上海',
        'categoryName': '火锅',
        'period': '2026-07',
        'updatedAt': '2026-07-20 10:00:00',
        'items': [
          {
            'position': 1,
            'rankScore': 94.7,
            'reason': '综合评分稳定',
            'shop': {
              'id': 10001,
              'name': '渝里火锅徐汇店',
              'score': 4.7,
              'currency': 'CNY',
              'pricePerCapita': 138,
              'cityName': '上海',
              'areaName': '徐汇',
              'merchantCertification': {
                'code': 'verified_merchant',
                'label': '认证商户',
              },
            },
          },
        ],
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  test('rank repository loads list and detail', () async {
    final api = RankFakeApi();
    final repository = RankRepository(api);

    final ranks = await repository.loadRanks();
    expect(api.path, '/api/c/v1/ranks');
    expect(ranks.single.name, '上海必吃榜');
    expect(ranks.single.type, 1);
    expect(ranks.single.topShopName, '渝里火锅徐汇店');

    final detail = await repository.loadRankDetail(30001);
    expect(api.path, '/api/c/v1/ranks/30001');
    expect(detail.type, 1);
    expect(detail.items.single.shop.name, '渝里火锅徐汇店');
    expect(detail.items.single.shop.merchantCertificationLabel, '认证商户');
  });
}
