import 'package:dazhongdianping_app/core/api_client.dart';

/// 固定广告位召回的一条广告（门店）。
class AdSlot {
  const AdSlot({
    required this.campaignId,
    required this.shopId,
    required this.shopName,
    required this.coverUrl,
    required this.score,
  });

  final int campaignId;
  final int shopId;
  final String shopName;
  final String coverUrl;
  final double score;

  factory AdSlot.fromJson(Map<String, dynamic> json) => AdSlot(
        campaignId: (json['campaignId'] as num?)?.toInt() ?? 0,
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        shopName: json['shopName'] as String? ?? '',
        coverUrl: json['coverUrl'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );
}

/// C端广告：固定坑位召回 + 点击上报计费。
class AdRepository {
  AdRepository(this.api);

  final JsonApi api;

  /// 召回广告位。slotType 1=搜索(带 keyword) 2=首页/列表。
  Future<List<AdSlot>> loadAdSlots({required int slotType, String? keyword, int limit = 3}) async {
    final query = <String, Object?>{'slotType': slotType, 'limit': limit};
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
    final result = await api.getJson('/api/c/v1/ads', query: query);
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(AdSlot.fromJson).toList();
  }

  /// 点击上报计费（尽力而为）。
  Future<void> reportClick(int campaignId) async {
    await api.postJson('/api/c/v1/ads/$campaignId/click');
  }
}
