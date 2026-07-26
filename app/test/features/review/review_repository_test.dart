import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ReviewFakeApi
    implements JsonApi, JsonMutationApi, JsonDeleteApi, FileUploadApi {
  String? method;
  String? path;
  Object? body;
  Map<String, Object?>? query;
  String? fieldName;
  Uint8List? uploadedBytes;
  String? fileName;
  String? contentType;

  Map<String, dynamic> get editorDetail => {
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

  Map<String, dynamic> get publicDetail => {
    'id': 12,
    'shopId': 7,
    'shopName': '柏林茶馆',
    'userId': 9,
    'userName': '阿遥',
    'content': '茶香很足，服务也利落。',
    'scoreOverall': 4.5,
    'scoreTaste': 5,
    'scoreEnv': 4,
    'scoreService': 4.5,
    'cost': 18.5,
    'currency': 'EUR',
    'likeCount': 3,
    'commentCount': 1,
    'likedByCurrentUser': false,
    'auditStatus': 1,
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'status': 1,
    'statusText': '正常',
    'authorCertification': {'code': 'local_expert', 'label': '本地达人'},
    'tags': ['适合朋友聚会', '中文服务'],
    'images': [
      {'id': 1, 'url': '/uploads/tea-1.png'},
    ],
    'merchantReply': {
      'merchantName': '柏林茶馆',
      'content': '谢谢支持',
      'repliedAt': '2026-07-20 12:00:00',
      'updatedAt': '2026-07-20 12:00:00',
    },
    'createdAt': '2026-07-19 18:00:00',
    'updatedAt': '2026-07-19 18:00:00',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    method = 'GET';
    this.path = path;
    this.query = query;
    if (path.endsWith('/comments')) {
      return {
        'list': [
          {
            'id': 81,
            'reviewId': 12,
            'userId': 2,
            'userName': '小李',
            'content': '说得对',
            'parentId': 0,
            'replyTo': null,
            'replies': [
              {
                'id': 82,
                'reviewId': 12,
                'userId': 3,
                'userName': '小王',
                'content': '我也这么觉得',
                'parentId': 81,
                'replyTo': {
                  'id': 81,
                  'userId': 2,
                  'userName': '小李',
                  'content': '说得对',
                },
                'replies': const [],
                'mine': false,
                'createdAt': '2026-07-19 19:10:00',
              },
            ],
            'mine': false,
            'createdAt': '2026-07-19 19:00:00',
          },
        ],
        'total': 1,
      };
    }
    if (path.startsWith('/api/c/v1/user/reviews/')) {
      return editorDetail;
    }
    if (path.startsWith('/api/c/v1/reviews/')) {
      return publicDetail;
    }
    return editorDetail;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    method = 'POST';
    this.path = path;
    this.body = body;
    if (path.endsWith('/like')) {
      return {'reviewId': 12, 'liked': true, 'likeCount': 4};
    }
    if (path.endsWith('/comments')) {
      return {
        'id': 90,
        'reviewId': 12,
        'userId': 1,
        'userName': '我',
        'content': (body as Map)['content'],
        'parentId': 0,
        'replyTo': null,
        'replies': const [],
        'mine': true,
        'createdAt': '2026-07-25 12:00:00',
      };
    }
    if (path.endsWith('/report')) {
      return {
        'id': 1,
        'reviewId': 12,
        'reason': (body as Map)['reason'],
        'status': 0,
        'statusText': '待处理',
        'createdAt': '2026-07-25 12:00:00',
      };
    }
    return editorDetail;
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    method = 'PUT';
    this.path = path;
    this.body = body;
    return editorDetail;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    method = 'DELETE';
    this.path = path;
    return const {};
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
  test(
    'review repository loads owned detail and normalizes image urls',
    () async {
      final api = ReviewFakeApi();
      final repository = ReviewRepository(api);

      final detail = await repository.loadOwnedReview(12);

      expect(api.path, '/api/c/v1/user/reviews/12');
      expect(detail.shopName, '柏林茶馆');
      expect(detail.scoreOverall, 4.5);
      expect(detail.images, ['/uploads/tea-1.png', '/uploads/tea-2.png']);
    },
  );

  test(
    'review repository loads public detail with merchant reply and badge',
    () async {
      final api = ReviewFakeApi();
      final repository = ReviewRepository(api);

      final detail = await repository.loadPublicReview(12);

      expect(api.path, '/api/c/v1/reviews/12');
      expect(detail.userName, '阿遥');
      expect(detail.likeCount, 3);
      expect(detail.authorCertificationLabel, '本地达人');
      expect(detail.merchantReply, '柏林茶馆：谢谢支持');
      expect(detail.canInteract, isTrue);
    },
  );

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

  test('review repository toggles like and loads nested comments', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    final like = await repository.toggleLike(12);
    expect(api.path, '/api/c/v1/reviews/12/like');
    expect(like.liked, isTrue);
    expect(like.likeCount, 4);

    final comments = await repository.loadComments(12);
    expect(api.path, '/api/c/v1/reviews/12/comments');
    expect(comments, hasLength(1));
    expect(comments.first.replies, hasLength(1));
    expect(comments.first.replies.first.replyTo?.userName, '小李');

    final page = await repository.loadCommentPage(12, page: 2, pageSize: 12);
    expect(api.query, {'page': 2, 'pageSize': 12});
    expect(page.page, 2);
    expect(page.pageSize, 12);
    expect(page.total, 1);
  });

  test('review repository creates comment and report payloads', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    await repository.createComment(12, '不错', replyTo: 81);
    expect(api.path, '/api/c/v1/reviews/12/comments');
    expect(api.body, {'content': '不错', 'replyTo': 81});

    final report = await repository.reportReview(12, '广告');
    expect(api.path, '/api/c/v1/reviews/12/report');
    expect(report.reason, '广告');
  });

  test('review repository deletes an owned review', () async {
    final api = ReviewFakeApi();
    final repository = ReviewRepository(api);

    await repository.deleteReview(12);

    expect(api.method, 'DELETE');
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
