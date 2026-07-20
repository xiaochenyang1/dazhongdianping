import 'dart:convert';
import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class EditorFakeApi implements JsonApi, JsonMutationApi, FileUploadApi {
  String? method;
  String? path;
  Object? body;
  String? uploadedFileName;

  Map<String, dynamic> detail({String? content}) => {
    'id': 12,
    'shopId': 7,
    'shopName': '柏林茶馆',
    'content': content ?? '原来的体验记录',
    'scoreOverall': 4,
    'scoreTaste': 5,
    'scoreEnv': 4,
    'scoreService': 4,
    'cost': 18,
    'currency': 'EUR',
    'auditStatusText': '待审核',
    'auditRemark': '',
    'tags': ['中文服务'],
    'images': const [],
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    method = 'GET';
    this.path = path;
    return detail();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    method = 'POST';
    this.path = path;
    this.body = body;
    final payload = body! as Map<String, Object?>;
    return detail(content: payload['content'] as String);
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    method = 'PUT';
    this.path = path;
    this.body = body;
    final payload = body! as Map<String, Object?>;
    return detail(content: payload['content'] as String);
  }

  @override
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required String fieldName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    method = 'UPLOAD';
    this.path = path;
    uploadedFileName = fileName;
    return {'url': '/uploads/$fileName'};
  }
}

class FakeReviewImagePicker implements ReviewImagePicker {
  @override
  Future<ReviewImageUpload?> pickImage() async => ReviewImageUpload(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    fileName: 'tea.png',
    contentType: 'image/png',
  );
}

Widget buildEditor({
  required EditorFakeApi api,
  int? reviewId,
  ReviewImagePicker? imagePicker,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: ReviewEditorScreen(
      repository: ReviewRepository(api),
      shopId: 7,
      shopName: '柏林茶馆',
      currency: 'EUR',
      reviewId: reviewId,
      imagePicker: imagePicker,
    ),
  );
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('review editor creates a review from validated form data', (
    tester,
  ) async {
    final api = EditorFakeApi();
    await tester.pumpWidget(buildEditor(api: api));

    expect(find.text('写点评'), findsOneWidget);
    expect(find.text('柏林茶馆'), findsOneWidget);

    await scrollTo(tester, find.byKey(const Key('review-content')));
    await tester.enterText(
      find.byKey(const Key('review-content')),
      '茶香很足，靠窗的位置也很舒服。',
    );
    await scrollTo(tester, find.byKey(const Key('review-cost')));
    await tester.enterText(find.byKey(const Key('review-cost')), '22.5');
    await scrollTo(tester, find.byKey(const Key('review-tags')));
    await tester.enterText(
      find.byKey(const Key('review-tags')),
      '适合朋友聚会, 中文服务',
    );
    await scrollTo(tester, find.byKey(const Key('review-submit')));
    await tester.tap(find.byKey(const Key('review-submit')));
    await tester.pumpAndSettle();

    expect(api.method, 'POST');
    expect(api.path, '/api/c/v1/reviews');
    expect(api.body, containsPair('shopId', 7));
    expect(api.body, containsPair('cost', 22.5));
    expect(
      api.body,
      containsPair('tags', ['适合朋友聚会', '中文服务']),
    );
  });

  testWidgets('review editor loads and updates an owned review', (tester) async {
    final api = EditorFakeApi();
    await tester.pumpWidget(buildEditor(api: api, reviewId: 12));
    await tester.pumpAndSettle();

    expect(find.text('编辑点评'), findsOneWidget);
    expect(find.text('原来的体验记录'), findsOneWidget);

    await scrollTo(tester, find.byKey(const Key('review-content')));
    await tester.enterText(
      find.byKey(const Key('review-content')),
      '修改后的真实体验记录',
    );
    await scrollTo(tester, find.byKey(const Key('review-submit')));
    await tester.tap(find.byKey(const Key('review-submit')));
    await tester.pumpAndSettle();

    expect(api.method, 'PUT');
    expect(api.path, '/api/c/v1/reviews/12');
    expect(api.body, containsPair('content', '修改后的真实体验记录'));
  });

  testWidgets('review editor picks and uploads an image before submission', (
    tester,
  ) async {
    final api = EditorFakeApi();
    await tester.pumpWidget(
      buildEditor(api: api, imagePicker: FakeReviewImagePicker()),
    );

    await scrollTo(tester, find.byKey(const Key('review-add-image')));
    await tester.tap(find.byKey(const Key('review-add-image')));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/files/upload');
    expect(api.uploadedFileName, 'tea.png');
    expect(find.text('已上传 1/9'), findsOneWidget);
  });

  testWidgets('review editor rejects empty content and invalid cost', (
    tester,
  ) async {
    final api = EditorFakeApi();
    await tester.pumpWidget(buildEditor(api: api));

    await scrollTo(tester, find.byKey(const Key('review-cost')));
    await tester.enterText(find.byKey(const Key('review-cost')), '-1');
    await scrollTo(tester, find.byKey(const Key('review-submit')));
    await tester.tap(find.byKey(const Key('review-submit')));
    await tester.pump();

    expect(find.text('请写下真实体验'), findsOneWidget);
    expect(find.text('请输入不小于 0 的金额'), findsOneWidget);
    expect(api.method, isNull);
  });
}
