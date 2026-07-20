import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';

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
      auditStatusText: json['auditStatusText'] as String? ?? '',
      auditRemark: json['auditRemark'] as String? ?? '',
    );
  }
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
      throw StateError('当前 API 客户端不支持 PUT 请求');
    }
    return api as JsonMutationApi;
  }

  FileUploadApi get _fileUploadApi {
    if (api is! FileUploadApi) {
      throw StateError('当前 API 客户端不支持文件上传');
    }
    return api as FileUploadApi;
  }
}
