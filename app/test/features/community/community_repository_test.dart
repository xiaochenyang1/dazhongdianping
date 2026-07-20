import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class CommunityFakeApi
    implements JsonApi, JsonMutationApi, JsonDeleteApi, FileUploadApi {
  String? method;
  String? path;
  Object? body;

  Map<String, dynamic> get post => {
    'id': 7,
    'userId': 9,
    'userName': '伦敦小王',
    'title': '伦敦周末市场指南',
    'content': '周六上午去选择最多。',
    'contentType': 1,
    'shopId': null,
    'dealId': null,
    'likeCount': 3,
    'commentCount': 1,
    'auditStatus': 1,
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'status': 1,
    'images': ['https://files.example/market.jpg'],
    'topics': ['伦敦生活'],
    'createdAt': '2026-07-16 10:00:00',
    'updatedAt': '2026-07-16 10:00:00',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    method = 'GET';
    this.path = path;
    if (path.endsWith('/comments')) {
      return {
        'list': [
          {
            'id': 11,
            'postId': 7,
            'userId': 10,
            'userName': '评论用户',
            'content': '收藏了。',
            'createdAt': '2026-07-16 11:00:00',
          },
        ],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/posts' ||
        path == '/api/c/v1/user/posts' ||
        path == '/api/c/v1/posts/following') {
      return {
        'list': [post],
        'total': 1,
      };
    }
    return post;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    method = 'POST';
    this.path = path;
    this.body = body;
    if (path.endsWith('/like')) {
      return {'postId': 7, 'liked': true, 'likeCount': 4};
    }
    if (path.endsWith('/comments')) {
      return {
        'id': 12,
        'postId': 7,
        'userId': 9,
        'userName': '伦敦小王',
        'content': (body as Map)['content'],
        'createdAt': '2026-07-16 12:00:00',
      };
    }
    if (path.endsWith('/report')) {
      return {
        'id': 13,
        'postId': 7,
        'reason': (body as Map)['reason'],
        'status': 0,
      };
    }
    return post;
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    method = 'PUT';
    this.path = path;
    this.body = body;
    return post;
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
    return {'url': '/uploads/$fileName'};
  }
}

const input = CommunityPostInput(
  title: '伦敦周末市场指南',
  content: '周六上午去选择最多。',
  contentType: 1,
  images: ['https://files.example/market.jpg'],
  topics: ['伦敦生活'],
);

void main() {
  test('community post input carries circle id', () {
    final input = CommunityPostInput(
      title: '圈子帖',
      content: '内容',
      contentType: 1,
      images: const [],
      topics: const [],
      circleId: 3,
    );
    expect(input.toJson()['circleId'], 3);
  });
  test('community repository loads public and owned posts', () async {
    final api = CommunityFakeApi();
    final repository = CommunityRepository(api);

    final feed = await repository.loadFeed();
    expect(api.path, '/api/c/v1/posts');
    expect(feed.single.title, '伦敦周末市场指南');

    final owned = await repository.loadOwnedPost(7);
    expect(api.path, '/api/c/v1/user/posts/7');
    expect(owned.topics, ['伦敦生活']);
  });

  test('community repository loads the authenticated following feed', () async {
    final api = CommunityFakeApi();
    final repository = CommunityRepository(api);
    final feed = await repository.loadFollowingFeed();
    expect(api.path, '/api/c/v1/posts/following');
    expect(feed.single.userName, '伦敦小王');
  });

  test(
    'community repository creates updates and deletes owned posts',
    () async {
      final api = CommunityFakeApi();
      final repository = CommunityRepository(api);

      await repository.createPost(input);
      expect(api.method, 'POST');
      expect(api.path, '/api/c/v1/posts');
      expect(api.body, containsPair('title', '伦敦周末市场指南'));
      expect(api.body, containsPair('topics', ['伦敦生活']));

      await repository.updatePost(7, input);
      expect(api.method, 'PUT');
      expect(api.path, '/api/c/v1/posts/7');

      await repository.deletePost(7);
      expect(api.method, 'DELETE');
      expect(api.path, '/api/c/v1/posts/7');
    },
  );

  test('community repository likes comments and reports a post', () async {
    final api = CommunityFakeApi();
    final repository = CommunityRepository(api);

    final like = await repository.toggleLike(7);
    expect(like.liked, isTrue);
    expect(like.likeCount, 4);

    final comment = await repository.createComment(7, '确实有用');
    expect(comment.content, '确实有用');

    final comments = await repository.loadComments(7);
    expect(comments.single.userName, '评论用户');

    await repository.reportPost(7, '信息过期');
    expect(api.path, '/api/c/v1/posts/7/report');
    expect(api.body, {'reason': '信息过期'});
  });

  test('community repository uploads post image bytes', () async {
    final api = CommunityFakeApi();
    final repository = CommunityRepository(api);
    final url = await repository.uploadImage(
      CommunityImageUpload(
        bytes: Uint8List.fromList([1, 2]),
        fileName: 'post.png',
        contentType: 'image/png',
      ),
    );
    expect(api.path, '/api/c/v1/files/upload');
    expect(url, '/uploads/post.png');
  });
}
