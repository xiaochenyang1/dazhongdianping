import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';

({String? code, String? label}) _badgeFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return (code: null, label: null);
  }
  final code = raw['code'];
  final label = raw['label'];
  return (
    code: code is String && code.trim().isNotEmpty ? code.trim() : null,
    label: label is String && label.trim().isNotEmpty ? label.trim() : null,
  );
}

class ReviewEditorData {
  const ReviewEditorData({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.content,
    required this.scoreOverall,
    required this.scoreTaste,
    required this.scoreEnv,
    required this.scoreService,
    required this.cost,
    required this.currency,
    required this.tags,
    required this.images,
    required this.auditStatus,
    required this.auditStatusText,
    required this.auditRemark,
  });

  final int id;
  final int shopId;
  final String shopName;
  final String content;
  final double scoreOverall;
  final double scoreTaste;
  final double scoreEnv;
  final double scoreService;
  final double cost;
  final String currency;
  final List<String> tags;
  final List<String> images;
  final int? auditStatus;
  final String auditStatusText;
  final String auditRemark;

  factory ReviewEditorData.fromJson(Map<String, dynamic> json) {
    final imageItems = json['images'] as List<dynamic>? ?? const [];
    return ReviewEditorData(
      id: json['id'] as int,
      shopId: json['shopId'] as int,
      shopName: json['shopName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      scoreOverall: (json['scoreOverall'] as num? ?? 5).toDouble(),
      scoreTaste: (json['scoreTaste'] as num? ?? 5).toDouble(),
      scoreEnv: (json['scoreEnv'] as num? ?? 5).toDouble(),
      scoreService: (json['scoreService'] as num? ?? 5).toDouble(),
      cost: (json['cost'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'CNY',
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      images: imageItems
          .map(
            (item) => item is String
                ? item
                : (item as Map<String, dynamic>)['url'] as String? ?? '',
          )
          .where((url) => url.isNotEmpty)
          .toList(),
      auditStatus: (json['auditStatus'] as num?)?.toInt(),
      auditStatusText: json['auditStatusText'] as String? ?? '',
      auditRemark: json['auditRemark'] as String? ?? '',
    );
  }
}

class ReviewDetail {
  const ReviewDetail({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.userId,
    required this.userName,
    required this.content,
    required this.scoreOverall,
    required this.scoreTaste,
    required this.scoreEnv,
    required this.scoreService,
    required this.cost,
    required this.currency,
    required this.likeCount,
    required this.commentCount,
    required this.likedByCurrentUser,
    required this.auditStatus,
    required this.auditStatusText,
    required this.auditRemark,
    required this.status,
    required this.statusText,
    required this.tags,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.authorCertificationCode,
    this.authorCertificationLabel,
    this.merchantReply,
  });

  final int id;
  final int shopId;
  final String shopName;
  final int userId;
  final String userName;
  final String content;
  final double scoreOverall;
  final double scoreTaste;
  final double scoreEnv;
  final double scoreService;
  final double cost;
  final String currency;
  final int likeCount;
  final int commentCount;
  final bool likedByCurrentUser;
  final int auditStatus;
  final String auditStatusText;
  final String auditRemark;
  final int status;
  final String statusText;
  final List<String> tags;
  final List<String> images;
  final String createdAt;
  final String updatedAt;
  final String? authorCertificationCode;
  final String? authorCertificationLabel;
  final String? merchantReply;

  bool get canInteract => auditStatus == 1 && status == 1;

  ReviewDetail copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByCurrentUser,
  }) => ReviewDetail(
    id: id,
    shopId: shopId,
    shopName: shopName,
    userId: userId,
    userName: userName,
    content: content,
    scoreOverall: scoreOverall,
    scoreTaste: scoreTaste,
    scoreEnv: scoreEnv,
    scoreService: scoreService,
    cost: cost,
    currency: currency,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
    auditStatus: auditStatus,
    auditStatusText: auditStatusText,
    auditRemark: auditRemark,
    status: status,
    statusText: statusText,
    tags: tags,
    images: images,
    createdAt: createdAt,
    updatedAt: updatedAt,
    authorCertificationCode: authorCertificationCode,
    authorCertificationLabel: authorCertificationLabel,
    merchantReply: merchantReply,
  );

  factory ReviewDetail.fromJson(Map<String, dynamic> json) {
    final imageItems = json['images'] as List<dynamic>? ?? const [];
    final author = _badgeFromJson(json['authorCertification']);
    final reply = json['merchantReply'];
    String? merchantReply;
    if (reply is Map<String, dynamic>) {
      final merchantName = reply['merchantName'] as String? ?? '';
      final content = reply['content'] as String? ?? '';
      if (content.trim().isNotEmpty) {
        merchantReply = merchantName.isEmpty
            ? content.trim()
            : '$merchantName：${content.trim()}';
      }
    }
    return ReviewDetail(
      id: json['id'] as int,
      shopId: json['shopId'] as int? ?? 0,
      shopName: json['shopName'] as String? ?? '',
      userId: json['userId'] as int? ?? 0,
      userName: json['userName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      scoreOverall: (json['scoreOverall'] as num? ?? 0).toDouble(),
      scoreTaste: (json['scoreTaste'] as num? ?? 0).toDouble(),
      scoreEnv: (json['scoreEnv'] as num? ?? 0).toDouble(),
      scoreService: (json['scoreService'] as num? ?? 0).toDouble(),
      cost: (json['cost'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'CNY',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      likedByCurrentUser: json['likedByCurrentUser'] as bool? ?? false,
      auditStatus: json['auditStatus'] as int? ?? 0,
      auditStatusText: json['auditStatusText'] as String? ?? '',
      auditRemark: json['auditRemark'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      statusText: json['statusText'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      images: imageItems
          .map(
            (item) => item is String
                ? item
                : (item as Map<String, dynamic>)['url'] as String? ?? '',
          )
          .where((url) => url.isNotEmpty)
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      authorCertificationCode: author.code,
      authorCertificationLabel: author.label,
      merchantReply: merchantReply,
    );
  }
}

class ReviewComment {
  const ReviewComment({
    required this.id,
    required this.reviewId,
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
  final int reviewId;
  final int userId;
  final String userName;
  final String content;
  final int parentId;
  final ReviewCommentReplyTarget? replyTo;
  final List<ReviewComment> replies;
  final bool mine;
  final String createdAt;

  factory ReviewComment.fromJson(Map<String, dynamic> json) => ReviewComment(
    id: json['id'] as int,
    reviewId: json['reviewId'] as int? ?? 0,
    userId: json['userId'] as int? ?? 0,
    userName: json['userName'] as String? ?? '',
    content: json['content'] as String? ?? '',
    parentId: json['parentId'] as int? ?? 0,
    replyTo: ReviewCommentReplyTarget.fromNullableJson(
      json['replyTo'] as Map<String, dynamic>?,
    ),
    replies: (json['replies'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ReviewComment.fromJson)
        .toList(),
    mine: json['mine'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class ReviewCommentReplyTarget {
  const ReviewCommentReplyTarget({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
  });

  final int id;
  final int userId;
  final String userName;
  final String content;

  factory ReviewCommentReplyTarget.fromJson(Map<String, dynamic> json) =>
      ReviewCommentReplyTarget(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );

  static ReviewCommentReplyTarget? fromNullableJson(
    Map<String, dynamic>? json,
  ) => json == null ? null : ReviewCommentReplyTarget.fromJson(json);
}

class ReviewCommentPage {
  const ReviewCommentPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });
  final List<ReviewComment> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
}

class ReviewLikeResult {
  const ReviewLikeResult({
    required this.reviewId,
    required this.liked,
    required this.likeCount,
  });

  final int reviewId;
  final bool liked;
  final int likeCount;

  factory ReviewLikeResult.fromJson(Map<String, dynamic> json) =>
      ReviewLikeResult(
        reviewId: json['reviewId'] as int? ?? 0,
        liked: json['liked'] as bool? ?? false,
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      );
}

class ReviewReportResult {
  const ReviewReportResult({
    required this.id,
    required this.reviewId,
    required this.reason,
    required this.status,
    required this.statusText,
    required this.createdAt,
  });

  final int id;
  final int reviewId;
  final String reason;
  final int status;
  final String statusText;
  final String createdAt;

  factory ReviewReportResult.fromJson(Map<String, dynamic> json) =>
      ReviewReportResult(
        id: json['id'] as int? ?? 0,
        reviewId: json['reviewId'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        status: json['status'] as int? ?? 0,
        statusText: json['statusText'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class ReviewSaveInput {
  const ReviewSaveInput({
    required this.shopId,
    required this.content,
    required this.scoreOverall,
    required this.scoreTaste,
    required this.scoreEnv,
    required this.scoreService,
    required this.cost,
    required this.currency,
    required this.tags,
    required this.images,
  });

  final int shopId;
  final String content;
  final double scoreOverall;
  final double scoreTaste;
  final double scoreEnv;
  final double scoreService;
  final double cost;
  final String currency;
  final List<String> tags;
  final List<String> images;

  Map<String, Object?> toJson() => {
    'shopId': shopId,
    'content': content,
    'scoreOverall': scoreOverall,
    'scoreTaste': scoreTaste,
    'scoreEnv': scoreEnv,
    'scoreService': scoreService,
    'cost': cost,
    'currency': currency,
    'tags': tags,
    'images': images,
  };
}

class ReviewImageUpload {
  const ReviewImageUpload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

class ReviewRepository {
  ReviewRepository(this.api);

  final JsonApi api;

  Future<ReviewEditorData> loadOwnedReview(int reviewId) async {
    final result = await api.getJson('/api/c/v1/user/reviews/$reviewId');
    return ReviewEditorData.fromJson(result);
  }

  Future<ReviewDetail> loadPublicReview(int reviewId) async {
    final result = await api.getJson('/api/c/v1/reviews/$reviewId');
    return ReviewDetail.fromJson(result);
  }

  Future<ReviewDetail> loadOwnedReviewDetail(int reviewId) async {
    final result = await api.getJson('/api/c/v1/user/reviews/$reviewId');
    return ReviewDetail.fromJson(result);
  }

  Future<ReviewEditorData> createReview(ReviewSaveInput input) async {
    final result = await api.postJson(
      '/api/c/v1/reviews',
      body: input.toJson(),
    );
    return ReviewEditorData.fromJson(result);
  }

  Future<ReviewEditorData> updateReview(
    int reviewId,
    ReviewSaveInput input,
  ) async {
    final result = await _mutationApi.putJson(
      '/api/c/v1/reviews/$reviewId',
      body: input.toJson(),
    );
    return ReviewEditorData.fromJson(result);
  }

  Future<ReviewLikeResult> toggleLike(int reviewId) async {
    final result = await api.postJson('/api/c/v1/reviews/$reviewId/like');
    return ReviewLikeResult.fromJson(result);
  }

  Future<List<ReviewComment>> loadComments(
    int reviewId, {
    int page = 1,
    int pageSize = 50,
  }) async =>
      (await loadCommentPage(reviewId, page: page, pageSize: pageSize)).items;

  Future<ReviewCommentPage> loadCommentPage(
    int reviewId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/reviews/$reviewId/comments',
      query: {'page': page, 'pageSize': pageSize},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    final items = list
        .cast<Map<String, dynamic>>()
        .map(ReviewComment.fromJson)
        .toList();
    return ReviewCommentPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
    );
  }

  Future<ReviewComment> createComment(
    int reviewId,
    String content, {
    int? replyTo,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/reviews/$reviewId/comments',
      body: {
        'content': content,
        if (replyTo != null && replyTo > 0) 'replyTo': replyTo,
      },
    );
    return ReviewComment.fromJson(result);
  }

  Future<ReviewReportResult> reportReview(int reviewId, String reason) async {
    final result = await api.postJson(
      '/api/c/v1/reviews/$reviewId/report',
      body: {'reason': reason},
    );
    return ReviewReportResult.fromJson(result);
  }

  Future<void> deleteReview(int reviewId) async {
    await _deleteApi.deleteJson('/api/c/v1/reviews/$reviewId');
  }

  Future<String> uploadImage(ReviewImageUpload image) async {
    final result = await _fileUploadApi.uploadBytes(
      '/api/c/v1/files/upload',
      fieldName: 'file',
      bytes: image.bytes,
      fileName: image.fileName,
      contentType: image.contentType,
    );
    return result['url'] as String;
  }

  JsonMutationApi get _mutationApi {
    if (api is! JsonMutationApi) {
      throw unsupportedApiClientCapability(
        'PUT requests',
        languageTag: apiClientLanguageTag(api),
      );
    }
    return api as JsonMutationApi;
  }

  JsonDeleteApi get _deleteApi {
    if (api is! JsonDeleteApi) {
      throw unsupportedApiClientCapability(
        'DELETE requests',
        languageTag: apiClientLanguageTag(api),
      );
    }
    return api as JsonDeleteApi;
  }

  FileUploadApi get _fileUploadApi {
    if (api is! FileUploadApi) {
      throw unsupportedApiClientCapability(
        'file uploads',
        languageTag: apiClientLanguageTag(api),
      );
    }
    return api as FileUploadApi;
  }
}
