import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ReviewFakeApi implements JsonApi, JsonMutationApi, FileUploadApi {
  String? method;
  String? path;
  Object? body;
  String? fieldName;
  Uint8List? uploadedBytes;
  String? fileName;
  String? contentType;

  Map<String, dynamic> get detail => {
    'id': 12,
    'shopId': 7,
    'shopName': '柏林茶馆',
    'content': '茶香很足，服务也利落。',
    'scoreOverall': 4.5,
    'scoreTaste': 5,
    'scoreEnv': 4,
    'scoreService': 4.5,
    'cost': 18.5,
    'currency': 'EUR',
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'tags': ['适合朋友聚会', '中文服务'],
    'images': [
      {'id': 1, 'url': '/uploads/tea-1.png'},
      {'id': 2, 'url': '/uploads/tea-2.png'},
    ],
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    method = 'GET';
    this.path = path;
    return detail;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    method = 'POST';
    this.path = path;
    this.body = body;
    return detail;
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    method = 'PUT';
    this.path = path;
    this.body = body;
    return detail;
  }

  @override
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required String fieldName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    method = 'UPLOAD';
    this.path = path;
    this.fieldName = fieldName;
    uploadedBytes = bytes;
    this.fileName = fileName;
    this.contentType = contentType;
    return {'url': '/uploads/$fileName'};
  }
}

const input = ReviewSaveInput(
  shopId: 7,
  content: '茶香很足，服务也利落。',
  scoreOverall: 4.5,
  scoreTaste: 5,
  scoreEnv: 4,
  scoreService: 4.5,
  cost: 18.5,
  currency: 'EUR',
  tags: ['适合朋友聚会', '中文服务'],
  images: ['/uploads/tea-1.png'],
);

void main() {
  test('review repository loads owned detail and normalizes image urls', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    final detail = await repository.loadOwnedReview(12);

    expect(api.path, '/api/c/v1/user/reviews/12');
    expect(detail.shopName, '柏林茶馆');
    expect(detail.scoreOverall, 4.5);
    expect(detail.images, ['/uploads/tea-1.png', '/uploads/tea-2.png']);
  });

  test('review repository creates a review with the backend payload', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    await repository.createReview(input);

    expect(api.method, 'POST');
    expect(api.path, '/api/c/v1/reviews');
    expect(api.body, {
      'shopId': 7,
      'content': '茶香很足，服务也利落。',
      'scoreOverall': 4.5,
      'scoreTaste': 5.0,
      'scoreEnv': 4.0,
      'scoreService': 4.5,
      'cost': 18.5,
      'currency': 'EUR',
      'tags': ['适合朋友聚会', '中文服务'],
      'images': ['/uploads/tea-1.png'],
    });
  });

  test('review repository updates an owned review', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    await repository.updateReview(12, input);

    expect(api.method, 'PUT');
    expect(api.path, '/api/c/v1/reviews/12');
  });

  test('review repository uploads image bytes and returns the url', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    final url = await repository.uploadImage(
      ReviewImageUpload(
        bytes: Uint8List.fromList([8, 9]),
        fileName: 'meal.png',
        contentType: 'image/png',
      ),
    );

    expect(api.path, '/api/c/v1/files/upload');
    expect(api.fieldName, 'file');
    expect(api.uploadedBytes, [8, 9]);
    expect(api.contentType, 'image/png');
    expect(url, '/uploads/meal.png');
  });
}
