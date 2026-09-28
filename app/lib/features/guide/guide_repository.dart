import 'package:dazhongdianping_app/core/api_client.dart';

class GuideArticle {
  const GuideArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.sections = const [],
  });

  final int id;
  final String title;
  final String summary;
  final List<GuideSection> sections;

  factory GuideArticle.fromJson(Map<String, dynamic> json) => GuideArticle(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GuideSection.fromJson)
            .toList(),
      );
}

class GuideSection {
  const GuideSection({required this.heading, required this.body, required this.shopId});

  final String heading;
  final String body;
  final int shopId;

  factory GuideSection.fromJson(Map<String, dynamic> json) => GuideSection(
        heading: json['heading'] as String? ?? '',
        body: json['body'] as String? ?? '',
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
      );
}

class GuideRepository {
  GuideRepository(this.api);

  final JsonApi api;

  Future<List<GuideArticle>> load() async {
    final result = await api.getJson('/api/c/v1/guides');
    final raw = result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(GuideArticle.fromJson).toList();
  }

  Future<GuideArticle> detail(int id) async {
    return GuideArticle.fromJson(await api.getJson('/api/c/v1/guides/$id'));
  }
}
