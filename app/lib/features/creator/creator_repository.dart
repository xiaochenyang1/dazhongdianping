import 'package:dazhongdianping_app/core/api_client.dart';

class CreatorTask {
  const CreatorTask({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.claimStatus,
    this.evidenceType,
    this.evidenceId,
    this.submissionNote = '',
    this.reviewNote = '',
  });

  final int id;
  final String title;
  final String description;
  final int rewardPoints;
  final int claimStatus;
  final String? evidenceType;
  final int? evidenceId;
  final String submissionNote;
  final String reviewNote;

  CreatorTask withStatus(int status) => CreatorTask(
    id: id,
    title: title,
    description: description,
    rewardPoints: rewardPoints,
    claimStatus: status,
    evidenceType: evidenceType,
    evidenceId: evidenceId,
    submissionNote: submissionNote,
    reviewNote: reviewNote,
  );

  factory CreatorTask.fromJson(Map<String, dynamic> json) => CreatorTask(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
    claimStatus: (json['claimStatus'] as num?)?.toInt() ?? 0,
    evidenceType: json['evidenceType'] as String?,
    evidenceId: (json['evidenceId'] as num?)?.toInt(),
    submissionNote: json['submissionNote'] as String? ?? '',
    reviewNote: json['reviewNote'] as String? ?? '',
  );
}

class CreatorEvidence {
  const CreatorEvidence({required this.id, required this.title});
  final int id;
  final String title;

  factory CreatorEvidence.fromJson(Map<String, dynamic> json) =>
      CreatorEvidence(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
      );
}

class CreatorPage<T> {
  const CreatorPage({required this.items, this.hasMore = false});
  final List<T> items;
  final bool hasMore;

  factory CreatorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = json['list'];
    return CreatorPage(
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(parse).toList()
          : [],
      hasMore: json['hasMore'] == true,
    );
  }
}

class CreatorRepository {
  CreatorRepository(this.api);

  final JsonApi api;

  Future<CreatorPage<CreatorTask>> load({int page = 1}) async {
    final result = await api.getJson(
      '/api/c/v1/creator/tasks',
      query: {'page': page, 'pageSize': 20},
    );
    return CreatorPage.fromJson(result, CreatorTask.fromJson);
  }

  Future<void> claim(int id) =>
      api.postJson('/api/c/v1/creator/tasks/$id/claim');

  Future<CreatorPage<CreatorEvidence>> evidence(
    String type, {
    int page = 1,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/creator/evidence',
      query: {'type': type, 'page': page, 'pageSize': 20},
    );
    return CreatorPage.fromJson(result, CreatorEvidence.fromJson);
  }

  Future<void> submit(
    int id, {
    required String type,
    required int evidenceId,
    required String note,
  }) => api.postJson(
    '/api/c/v1/creator/tasks/$id/submit',
    body: {'evidenceType': type, 'evidenceId': evidenceId, 'note': note.trim()},
  );
}
