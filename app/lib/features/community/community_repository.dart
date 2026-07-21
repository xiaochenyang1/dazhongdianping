import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.contentType,
    required this.likeCount,
    required this.commentCount,
    required this.repostCount,
    required this.repostedByCurrentUser,
    required this.auditStatus,
    required this.auditStatusText,
    required this.auditRemark,
    required this.images,
    required this.topics,
    required this.createdAt,
    this.shopId,
    this.dealId,
    this.circleId,
  });

  final int id;
  final int userId;
  final String userName;
  final String title;
  final String content;
  final int contentType;
  final int? shopId;
  final int? dealId;
  final int? circleId;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final bool repostedByCurrentUser;
  final int auditStatus;
  final String auditStatusText;
  final String auditRemark;
  final List<String> images;
  final List<String> topics;
  final String createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: json['id'] as int,
    userId: json['userId'] as int? ?? 0,
    userName: json['userName'] as String? ?? '',
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    contentType: json['contentType'] as int? ?? 1,
    shopId: json['shopId'] as int?,
    dealId: json['dealId'] as int?,
    circleId: json['circleId'] as int?,
    likeCount: json['likeCount'] as int? ?? 0,
    commentCount: json['commentCount'] as int? ?? 0,
    repostCount: json['repostCount'] as int? ?? 0,
    repostedByCurrentUser: json['repostedByCurrentUser'] as bool? ?? false,
    auditStatus: json['auditStatus'] as int? ?? 0,
    auditStatusText: json['auditStatusText'] as String? ?? '',
    auditRemark: json['auditRemark'] as String? ?? '',
    images: (json['images'] as List<dynamic>? ?? const []).cast<String>(),
    topics: (json['topics'] as List<dynamic>? ?? const []).cast<String>(),
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class CommunityPostInput {
  const CommunityPostInput({
    required this.title,
    required this.content,
    required this.contentType,
    required this.images,
    required this.topics,
    this.shopId,
    this.dealId,
    this.circleId,
  });
  final String title;
  final String content;
  final int contentType;
  final int? shopId;
  final int? dealId;
  final int? circleId;
  final List<String> images;
  final List<String> topics;

  Map<String, Object?> toJson() => {
    'title': title,
    'content': content,
    'contentType': contentType,
    'shopId': shopId,
    'dealId': dealId,
    'circleId': circleId,
    'images': images,
    'topics': topics,
  };
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.parentId,
    required this.replyTo,
    required this.replies,
    required this.mine,
    required this.createdAt,
  });
  final int id;
  final int postId;
  final int userId;
  final String userName;
  final String content;
  final int parentId;
  final CommunityCommentReplyTarget? replyTo;
  final List<CommunityComment> replies;
  final bool mine;
  final String createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) =>
      CommunityComment(
        id: json['id'] as int,
        postId: json['postId'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        content: json['content'] as String? ?? '',
        parentId: json['parentId'] as int? ?? 0,
        replyTo: CommunityCommentReplyTarget.fromNullableJson(
          json['replyTo'] as Map<String, dynamic>?,
        ),
        replies: (json['replies'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CommunityComment.fromJson)
            .toList(),
        mine: json['mine'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class CommunityCommentReplyTarget {
  const CommunityCommentReplyTarget({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
  });

  final int id;
  final int userId;
  final String userName;
  final String content;

  factory CommunityCommentReplyTarget.fromJson(Map<String, dynamic> json) =>
      CommunityCommentReplyTarget(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );

  static CommunityCommentReplyTarget? fromNullableJson(
    Map<String, dynamic>? json,
  ) => json == null ? null : CommunityCommentReplyTarget.fromJson(json);
}

class CommunityLikeResult {
  const CommunityLikeResult({required this.liked, required this.likeCount});
  final bool liked;
  final int likeCount;
}

class CommunityRepostResult {
  const CommunityRepostResult({
    required this.postId,
    required this.reposted,
    required this.repostCount,
  });
  final int postId;
  final bool reposted;
  final int repostCount;

  factory CommunityRepostResult.fromJson(Map<String, dynamic> json) =>
      CommunityRepostResult(
        postId: json['postId'] as int? ?? 0,
        reposted: json['reposted'] as bool? ?? false,
        repostCount: json['repostCount'] as int? ?? 0,
      );
}

class CommunityImageUpload {
  const CommunityImageUpload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

class CommunityRepository {
  CommunityRepository(this.api);
  final JsonApi api;

  Future<List<CommunityPost>> loadFeed() => _loadPage('/api/c/v1/posts');
  Future<List<CommunityPost>> loadFollowingFeed() =>
      _loadPage('/api/c/v1/posts/following');
  Future<List<CommunityPost>> loadOwnedPosts() =>
      _loadPage('/api/c/v1/user/posts');

  Future<List<CommunityPost>> _loadPage(String path) async {
    final result = await api.getJson(
      path,
      query: const {'page': 1, 'pageSize': 30},
    );
    return (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(CommunityPost.fromJson)
        .toList();
  }

  Future<CommunityPost> loadPost(int postId) async =>
      CommunityPost.fromJson(await api.getJson('/api/c/v1/posts/$postId'));

  Future<CommunityPost> loadOwnedPost(int postId) async =>
      CommunityPost.fromJson(await api.getJson('/api/c/v1/user/posts/$postId'));

  Future<CommunityPost> createPost(CommunityPostInput input) async =>
      CommunityPost.fromJson(
        await api.postJson('/api/c/v1/posts', body: input.toJson()),
      );

  Future<CommunityPost> updatePost(
    int postId,
    CommunityPostInput input,
  ) async => CommunityPost.fromJson(
    await _mutationApi.putJson('/api/c/v1/posts/$postId', body: input.toJson()),
  );

  Future<void> deletePost(int postId) async {
    await _deleteApi.deleteJson('/api/c/v1/posts/$postId');
  }

  Future<CommunityLikeResult> toggleLike(int postId) async {
    final result = await api.postJson('/api/c/v1/posts/$postId/like');
    return CommunityLikeResult(
      liked: result['liked'] as bool? ?? false,
      likeCount: result['likeCount'] as int? ?? 0,
    );
  }

  Future<CommunityRepostResult> repostPost(int postId) async =>
      CommunityRepostResult.fromJson(
        await api.postJson('/api/c/v1/posts/$postId/repost'),
      );

  Future<CommunityRepostResult> removeRepost(int postId) async =>
      CommunityRepostResult.fromJson(
        await _deleteApi.deleteJson('/api/c/v1/posts/$postId/repost'),
      );

  Future<List<CommunityComment>> loadComments(int postId) async {
    final result = await api.getJson(
      '/api/c/v1/posts/$postId/comments',
      query: const {'page': 1, 'pageSize': 50},
    );
    return (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(CommunityComment.fromJson)
        .toList();
  }

  Future<CommunityComment> createComment(
    int postId,
    String content, {
    int? replyTo,
  }) async =>
      CommunityComment.fromJson(
        await api.postJson(
          '/api/c/v1/posts/$postId/comments',
          body: {
            'content': content,
            if (replyTo != null) 'replyTo': replyTo,
          },
        ),
      );

  Future<void> reportPost(int postId, String reason) async {
    await api.postJson(
      '/api/c/v1/posts/$postId/report',
      body: {'reason': reason},
    );
  }

  Future<void> favoritePost(int postId) async {
    await api.postJson(
      '/api/c/v1/favorites',
      body: {'targetType': 2, 'targetId': postId},
    );
  }

  Future<void> unfavoritePost(int postId) async {
    await (api as JsonDeleteApi).deleteJson(
      '/api/c/v1/favorites?targetType=2&targetId=$postId',
    );
  }

  Future<String> uploadImage(CommunityImageUpload image) async {
    final result = await _uploadApi.uploadBytes(
      '/api/c/v1/files/upload',
      fieldName: 'file',
      bytes: image.bytes,
      fileName: image.fileName,
      contentType: image.contentType,
    );
    return result['url'] as String;
  }

  JsonMutationApi get _mutationApi => api is JsonMutationApi
      ? api as JsonMutationApi
      : throw StateError('当前 API 客户端不支持 PUT 请求');
  JsonDeleteApi get _deleteApi => api is JsonDeleteApi
      ? api as JsonDeleteApi
      : throw StateError('当前 API 客户端不支持 DELETE 请求');
  FileUploadApi get _uploadApi => api is FileUploadApi
      ? api as FileUploadApi
      : throw StateError('当前 API 客户端不支持文件上传');
}
