import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/marketing/marketing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MarketingFakeApi implements JsonApi {
  MarketingFakeApi({this.getResponse = const {}, this.postResponse = const {}});

  Map<String, dynamic> getResponse;
  Map<String, dynamic> postResponse;
  String? getPath;
  Map<String, Object?>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }
}

void main() {
  test('loadCenter parses claimable coupon templates', () async {
    final api = MarketingFakeApi(getResponse: {
      'value': [
        {
          'id': 5001,
          'name': '满100减20',
          'type': 1,
          'typeText': '满减券',
          'thresholdAmount': 100,
          'discountAmount': 20,
          'currency': 'CNY',
          'shopId': 0,
          'perUserLimit': 1,
          'validDays': 30,
          'claimed': false,
          'soldOut': false,
          'claimable': true,
        },
      ],
    });
    final repository = MarketingRepository(api);

    final items = await repository.loadCenter();

    expect(api.getPath, '/api/c/v1/marketing/coupons/center');
    expect(items.single.id, 5001);
    expect(items.single.discountAmount, 20);
    expect(items.single.claimable, true);
  });

  test('claim posts to the template claim endpoint', () async {
    final api = MarketingFakeApi(postResponse: {
      'id': 9001,
      'templateId': 5001,
      'templateName': '满100减20',
      'type': 1,
      'typeText': '满减券',
      'thresholdAmount': 100,
      'discountAmount': 20,
      'currency': 'CNY',
      'shopId': 0,
      'status': 1,
      'statusText': '未使用',
    });
    final repository = MarketingRepository(api);

    final coupon = await repository.claim(5001);

    expect(api.postPath, '/api/c/v1/marketing/coupons/5001/claim');
    expect(coupon.id, 9001);
    expect(coupon.status, 1);
  });

  test('loadMyCoupons reads the paginated list envelope', () async {
    final api = MarketingFakeApi(getResponse: {
      'list': [
        {
          'id': 9001,
          'templateId': 5001,
          'templateName': '满100减20',
          'type': 1,
          'typeText': '满减券',
          'thresholdAmount': 100,
          'discountAmount': 20,
          'currency': 'CNY',
          'shopId': 0,
          'status': 2,
          'statusText': '已使用',
        },
      ],
      'total': 1,
    });
    final repository = MarketingRepository(api);

    final coupons = await repository.loadMyCoupons(status: 2);

    expect(api.getPath, '/api/c/v1/marketing/coupons/mine');
    expect(api.getQuery?['status'], 2);
    expect(coupons.single.status, 2);
    expect(coupons.single.templateName, '满100减20');
  });

  test('loadUsableCoupons passes deal id and quantity', () async {
    final api = MarketingFakeApi(getResponse: {'value': const []});
    final repository = MarketingRepository(api);

    final coupons = await repository.loadUsableCoupons(42, quantity: 3);

    expect(api.getPath, '/api/c/v1/deals/42/usable-coupons');
    expect(api.getQuery?['quantity'], 3);
    expect(coupons, isEmpty);
  });
}
