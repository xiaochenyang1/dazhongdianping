import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';

/// 用户行为埋点类型：1=浏览店铺 2=收藏 3=下单 4=搜索关键词。
enum BehaviorEventType {
  viewShop(1),
  favorite(2),
  order(3),
  search(4);

  const BehaviorEventType(this.code);
  final int code;
}

/// 个性化推荐仓库：拉取"猜你喜欢" feed，并上报用户行为埋点。
class RecommendationRepository {
  RecommendationRepository(this.api);

  final JsonApi api;

  /// 拉取推荐店铺 feed。匿名可用；登录后基于行为个性化。
  Future<List<ShopSummary>> loadFeed({
    double? latitude,
    double? longitude,
    int? cityId,
    int limit = 12,
  }) async {
    final query = <String, Object?>{'limit': limit};
    if (latitude != null) query['latitude'] = latitude;
    if (longitude != null) query['longitude'] = longitude;
    if (cityId != null) query['cityId'] = cityId;

    final result = await api.getJson('/api/c/v1/recommendations/feed', query: query);
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ShopSummary.fromJson)
        .where((item) => item.id > 0)
        .toList();
  }

  /// 上报一条用户行为埋点（需登录；未登录时后端忽略）。
  Future<void> trackBehavior({
    required BehaviorEventType eventType,
    int? shopId,
    int? categoryId,
    String? keyword,
  }) async {
    await api.postJson('/api/c/v1/recommendations/behaviors', body: {
      'eventType': eventType.code,
      if (shopId != null) 'shopId': shopId,
      if (categoryId != null) 'categoryId': categoryId,
      if (keyword != null) 'keyword': keyword,
    });
  }
}
