import 'package:dazhongdianping_app/core/api_client.dart';

class CreatorTask {
  const CreatorTask({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.claimStatus,
  });

  final int id;
  final String title;
  final String description;
  final int rewardPoints;
  final int claimStatus;

  factory CreatorTask.fromJson(Map<String, dynamic> json) => CreatorTask(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
    claimStatus: (json['claimStatus'] as num?)?.toInt() ?? 0,
  );
}

class CreatorRepository {
  CreatorRepository(this.api);

  final JsonApi api;

  Future<List<CreatorTask>> load() async {
    final result = await api.getJson('/api/c/v1/creator/tasks');
    final raw = result['list'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CreatorTask.fromJson)
        .toList();
  }

  Future<void> claim(int id) =>
      api.postJson('/api/c/v1/creator/tasks/$id/claim');

  Future<void> complete(int id) =>
      api.postJson('/api/c/v1/creator/tasks/$id/complete');
}
