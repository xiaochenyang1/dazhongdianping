import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/creator/creator_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class CreatorFakeApi implements JsonApi {
  Map<String, dynamic> response = {};
  String? path;
  Map<String, Object?>? query;
  Object? body;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    return response;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    return response;
  }
}

void main() {
  test(
    'reads paged tasks with frozen terms and rejected submission details',
    () async {
      final api = CreatorFakeApi()
        ..response = {
          'list': [
            {
              'id': 10,
              'title': 'Original title',
              'description': 'Original terms',
              'rewardPoints': 20,
              'claimStatus': 4,
              'evidenceType': 'post',
              'evidenceId': 81,
              'submissionNote': 'My explanation',
              'reviewNote': 'Add a photo',
            },
          ],
          'hasMore': true,
        };
      final result = await CreatorRepository(api).load(page: 2);
      expect(api.path, '/api/c/v1/creator/tasks');
      expect(api.query, {'page': 2, 'pageSize': 20});
      expect(result.hasMore, isTrue);
      final item = result.items.single;
      expect(item.claimStatus, 4);
      expect(item.rewardPoints, 20);
      expect(item.description, 'Original terms');
      expect(item.evidenceType, 'post');
      expect(item.evidenceId, 81);
      expect(item.submissionNote, 'My explanation');
      expect(item.reviewNote, 'Add a photo');
    },
  );

  test(
    'loads paged published evidence and submits its reference for review',
    () async {
      final api = CreatorFakeApi()
        ..response = {
          'list': [
            {'id': 81, 'title': 'My work'},
          ],
          'hasMore': false,
        };
      final repository = CreatorRepository(api);
      final work = await repository.evidence('post', page: 3);
      expect(api.query, {'type': 'post', 'page': 3, 'pageSize': 20});
      expect(work.items.single.title, 'My work');
      expect(work.hasMore, isFalse);
      await repository.claim(10);
      expect(api.path, '/api/c/v1/creator/tasks/10/claim');
      await repository.submit(
        10,
        type: 'post',
        evidenceId: work.items.single.id,
        note: ' Ready ',
      );
      expect(api.path, '/api/c/v1/creator/tasks/10/submit');
      expect(api.body, {
        'evidenceType': 'post',
        'evidenceId': 81,
        'note': 'Ready',
      });
    },
  );
}
