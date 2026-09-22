import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/complaint/complaint_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ComplaintFakeApi implements JsonApi {
  ComplaintFakeApi({this.getResponse = const {}, this.postResponse = const {}});

  Map<String, dynamic> getResponse;
  Map<String, dynamic> postResponse;
  String? getPath;
  Map<String, Object?>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, Object?>? query}) async {
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

Map<String, dynamic> ticketJson() => {
      'id': 7001,
      'ticketNo': 'CT0001',
      'shopId': 10001,
      'shopName': '沪上渝里',
      'orderId': 0,
      'type': 1,
      'typeText': '商品/服务质量',
      'title': '分量不符',
      'content': '套餐份量偏少。',
      'status': 1,
      'statusText': '待受理',
      'merchantReply': '',
      'resolution': '',
      'createdAt': '2026-09-22 10:00:00',
      'logs': [
        {'id': 1, 'actorTypeText': '用户', 'actionText': '创建投诉', 'remark': '套餐份量偏少。', 'createdAt': '2026-09-22 10:00:00'},
      ],
    };

void main() {
  test('createComplaint posts payload and parses ticket', () async {
    final api = ComplaintFakeApi(postResponse: ticketJson());
    final repository = ComplaintRepository(api);

    final ticket = await repository.createComplaint(
      shopId: 10001,
      orderId: 55,
      type: 1,
      title: '分量不符',
      content: '套餐份量偏少。',
    );

    expect(api.postPath, '/api/c/v1/complaints');
    final body = api.postBody as Map<String, dynamic>;
    expect(body['shopId'], 10001);
    expect(body['orderId'], 55);
    expect(body['type'], 1);
    expect(ticket.id, 7001);
    expect(ticket.logs.single.actionText, '创建投诉');
  });

  test('createComplaint omits orderId when null', () async {
    final api = ComplaintFakeApi(postResponse: ticketJson());
    final repository = ComplaintRepository(api);

    await repository.createComplaint(shopId: 10001, type: 2, title: 't', content: 'c');

    final body = api.postBody as Map<String, dynamic>;
    expect(body.containsKey('orderId'), false);
  });

  test('loadMyComplaints reads the paginated list envelope with status', () async {
    final api = ComplaintFakeApi(getResponse: {'list': [ticketJson()], 'total': 1});
    final repository = ComplaintRepository(api);

    final tickets = await repository.loadMyComplaints(status: 1);

    expect(api.getPath, '/api/c/v1/complaints');
    expect(api.getQuery?['status'], 1);
    expect(tickets.single.ticketNo, 'CT0001');
  });

  test('loadComplaint parses a single ticket', () async {
    final api = ComplaintFakeApi(getResponse: ticketJson());
    final repository = ComplaintRepository(api);

    final ticket = await repository.loadComplaint(7001);

    expect(api.getPath, '/api/c/v1/complaints/7001');
    expect(ticket.title, '分量不符');
  });
}
