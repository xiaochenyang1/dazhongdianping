import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_config.dart';

class LaunchCapabilities {
  const LaunchCapabilities({
    this.region = '',
    this.creatorRewards = false,
    this.seckill = false,
    this.groupBuy = false,
  });

  final String region;
  final bool creatorRewards;
  final bool seckill;
  final bool groupBuy;

  static Future<LaunchCapabilities> load(
    JsonApi api, {
    AppRegion? region,
  }) async {
    final expectedRegion =
        region?.code ?? (api is ApiClient ? api.regionProvider().code : null);
    try {
      final data = await api.getJson('/api/c/v1/launch-config');
      final actualRegion = data['region'];
      if ((actualRegion != 'CN' && actualRegion != 'EU') ||
          (expectedRegion != null && actualRegion != expectedRegion) ||
          (api is ApiClient && api.regionProvider().code != actualRegion)) {
        return const LaunchCapabilities();
      }
      return LaunchCapabilities(
        region: actualRegion as String,
        creatorRewards: data['creatorRewards'] == true,
        seckill: data['seckill'] == true,
        groupBuy: data['groupBuy'] == true,
      );
    } catch (_) {
      return const LaunchCapabilities();
    }
  }
}
