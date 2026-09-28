import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/qa/qa_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class QaFakeApi implements JsonApi {
  QaFakeApi({this.getResponse = const {}, this.postResponse = const {}});

  Map<String, dynamic> getResponse;
  Map<String, dynamic> postResponse;
  String? getPath;
  Map<String, Object?>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, Object?>? query}) async {
    getPath = path;
    getQuery = query;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }
}

void main() {
  test('loadQuestions reads the paginated list envelope', () async {
    final api = QaFakeApi(getResponse: {
      'list': [
        {'id': 7, 'userNickname': '阿木', 'content': '需要预约吗？', 'answerCount': 2, 'latestAnswer': '建议预约'},
      ],
      'total': 1,
    });
    final repository = QaRepository(api);

    final questions = await repository.loadQuestions(10001);

    expect(api.getPath, '/api/c/v1/shops/10001/questions');
    expect(api.getQuery?['page'], 1);
    expect(questions.single.answerCount, 2);
    expect(questions.single.latestAnswer, '建议预约');
  });

  test('ask posts a question', () async {
    final api = QaFakeApi(postResponse: {'id': 8, 'userNickname': '阿木', 'content': '有停车位吗', 'answerCount': 0, 'latestAnswer': ''});
    final repository = QaRepository(api);

    final q = await repository.ask(10001, '有停车位吗');

    expect(api.postPath, '/api/c/v1/shops/10001/questions');
    expect((api.postBody as Map<String, dynamic>)['content'], '有停车位吗');
    expect(q.id, 8);
  });

  test('loadAnswers and answer hit the nested endpoints', () async {
    final api = QaFakeApi(
      getResponse: {'value': [{'id': 1, 'userNickname': '客', 'content': '建议预约'}]},
      postResponse: {'id': 2, 'userNickname': '我', 'content': '好的'},
    );
    final repository = QaRepository(api);

    final answers = await repository.loadAnswers(10001, 7);
    expect(api.getPath, '/api/c/v1/shops/10001/questions/7/answers');
    expect(answers.single.content, '建议预约');

    final posted = await repository.answer(10001, 7, '好的');
    expect(api.postPath, '/api/c/v1/shops/10001/questions/7/answers');
    expect((api.postBody as Map<String, dynamic>)['content'], '好的');
    expect(posted.id, 2);
  });
}
