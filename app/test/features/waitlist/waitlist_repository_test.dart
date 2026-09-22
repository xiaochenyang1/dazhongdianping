import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/waitlist/waitlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class WaitlistFakeApi implements JsonApi {
  WaitlistFakeApi({this.getResponse = const {}, this.postResponse = const {}});

  Map<String, dynamic> getResponse;
  Map<String, dynamic> postResponse;
  String? getPath;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, Object?>? query}) async {
    getPath = path;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }
}

Map<String, dynamic> entryJson({int status = 1}) => {
      'id': 1, 'shopId': 10001, 'shopName': '沪上渝里', 'tableType': 1, 'tableTypeText': '小桌',
      'partySize': 2, 'queueNo': 3, 'status': status, 'statusText': '排队中', 'aheadCount': 2,
    };

void main() {
  test('join posts table type and party size', () async {
    final api = WaitlistFakeApi(postResponse: entryJson());
    final repository = WaitlistRepository(api);

    final entry = await repository.join(10001, tableType: 2, partySize: 4);

    expect(api.postPath, '/api/c/v1/shops/10001/waitlist');
    final body = api.postBody as Map<String, dynamic>;
    expect(body['tableType'], 2);
    expect(body['partySize'], 4);
    expect(entry.aheadCount, 2);
  });

  test('loadMine reads the value list envelope', () async {
    final api = WaitlistFakeApi(getResponse: {'value': [entryJson()]});
    final repository = WaitlistRepository(api);

    final entries = await repository.loadMine();

    expect(api.getPath, '/api/c/v1/waitlist/mine');
    expect(entries.single.queueNo, 3);
  });

  test('cancel posts to the cancel endpoint', () async {
    final api = WaitlistFakeApi(postResponse: entryJson(status: 5));
    final repository = WaitlistRepository(api);

    final entry = await repository.cancel(1);

    expect(api.postPath, '/api/c/v1/waitlist/1/cancel');
    expect(entry.status, 5);
  });
}
