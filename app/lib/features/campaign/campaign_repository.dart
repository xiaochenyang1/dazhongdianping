import 'package:dazhongdianping_app/core/api_client.dart';

class SeckillEvent {
  const SeckillEvent({
    required this.id,
    required this.title,
    required this.dealId,
    required this.seckillPrice,
    required this.stock,
    required this.sold,
  });

  final int id;
  final String title;
  final int dealId;
  final num seckillPrice;
  final int stock;
  final int sold;

  factory SeckillEvent.fromJson(Map<String, dynamic> json) => SeckillEvent(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        dealId: (json['dealId'] as num?)?.toInt() ?? 0,
        seckillPrice: json['seckillPrice'] as num? ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        sold: (json['sold'] as num?)?.toInt() ?? 0,
      );
}

class GroupBuyCampaign {
  const GroupBuyCampaign({
    required this.id,
    required this.title,
    required this.dealId,
    required this.groupPrice,
    required this.groupSize,
  });

  final int id;
  final String title;
  final int dealId;
  final num groupPrice;
  final int groupSize;

  factory GroupBuyCampaign.fromJson(Map<String, dynamic> json) => GroupBuyCampaign(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        dealId: (json['dealId'] as num?)?.toInt() ?? 0,
        groupPrice: json['groupPrice'] as num? ?? 0,
        groupSize: (json['groupSize'] as num?)?.toInt() ?? 2,
      );
}

class CampaignRepository {
  CampaignRepository(this.api);

  final JsonApi api;

  Future<List<SeckillEvent>> seckill() async {
    final result = await api.getJson('/api/c/v1/marketing/seckill');
    final raw = result['list'] ?? result['value'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(SeckillEvent.fromJson).toList();
    }
    return const [];
  }

  Future<void> claim(int id) => api.postJson('/api/c/v1/marketing/seckill/$id/claim');

  Future<List<GroupBuyCampaign>> groupBuy() async {
    final result = await api.getJson('/api/c/v1/marketing/groupbuy');
    final raw = result['list'] ?? result['value'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(GroupBuyCampaign.fromJson).toList();
    }
    return const [];
  }

  Future<int> openTeam(int campaignId) async {
    final result = await api.postJson('/api/c/v1/marketing/groupbuy/$campaignId/teams');
    return (result['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> joinTeam(int teamId) => api.postJson('/api/c/v1/marketing/groupbuy/teams/$teamId/join');
}

class LevelPrivileges {
  const LevelPrivileges({required this.level, required this.levelName, required this.growthValue, required this.privileges});

  final int level;
  final String levelName;
  final int growthValue;
  final String privileges;

  factory LevelPrivileges.fromJson(Map<String, dynamic> json) => LevelPrivileges(
        level: (json['level'] as num?)?.toInt() ?? 0,
        levelName: json['levelName'] as String? ?? '',
        growthValue: (json['growthValue'] as num?)?.toInt() ?? 0,
        privileges: json['privileges']?.toString() ?? '',
      );
}

class GrowthRepository {
  GrowthRepository(this.api);

  final JsonApi api;

  Future<LevelPrivileges> privileges() async {
    return LevelPrivileges.fromJson(await api.getJson('/api/c/v1/user/level-privileges'));
  }
}
