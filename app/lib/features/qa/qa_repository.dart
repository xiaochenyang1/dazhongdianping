import 'package:dazhongdianping_app/core/api_client.dart';

/// 门店问答-问题。
class ShopQuestion {
  const ShopQuestion({
    required this.id,
    required this.userNickname,
    required this.content,
    required this.answerCount,
    required this.latestAnswer,
    this.createdAt,
  });

  final int id;
  final String userNickname;
  final String content;
  final int answerCount;
  final String latestAnswer;
  final String? createdAt;

  factory ShopQuestion.fromJson(Map<String, dynamic> json) => ShopQuestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userNickname: json['userNickname'] as String? ?? '',
        content: json['content'] as String? ?? '',
        answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
        latestAnswer: json['latestAnswer'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
      );
}

/// 门店问答-回答。
class ShopAnswer {
  const ShopAnswer({
    required this.id,
    required this.userNickname,
    required this.content,
    this.createdAt,
  });

  final int id;
  final String userNickname;
  final String content;
  final String? createdAt;

  factory ShopAnswer.fromJson(Map<String, dynamic> json) => ShopAnswer(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userNickname: json['userNickname'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
      );
}

/// "问大家" 仓库：门店问答浏览与发布。
class QaRepository {
  QaRepository(this.api);

  final JsonApi api;

  Future<List<ShopQuestion>> loadQuestions(int shopId, {int page = 1, int pageSize = 10}) async {
    final result = await api.getJson(
      '/api/c/v1/shops/$shopId/questions',
      query: {'page': page, 'pageSize': pageSize},
    );
    final raw = result['list'] ?? result['value'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(ShopQuestion.fromJson).toList();
  }

  Future<ShopQuestion> ask(int shopId, String content) async {
    final result = await api.postJson('/api/c/v1/shops/$shopId/questions', body: {'content': content});
    return ShopQuestion.fromJson(result);
  }

  Future<List<ShopAnswer>> loadAnswers(int shopId, int questionId) async {
    final result = await api.getJson('/api/c/v1/shops/$shopId/questions/$questionId/answers');
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(ShopAnswer.fromJson).toList();
  }

  Future<ShopAnswer> answer(int shopId, int questionId, String content) async {
    final result = await api.postJson(
      '/api/c/v1/shops/$shopId/questions/$questionId/answers',
      body: {'content': content},
    );
    return ShopAnswer.fromJson(result);
  }
}
