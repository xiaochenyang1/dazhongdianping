import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/consult/consult_chat_screen.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class TestApi implements JsonApi {
  String? postedPath;
  Map<String, dynamic> notification = {
    'id': 1,
    'type': 'consult.reply',
    'title': '商家回复了你的咨询',
    'content': 'Your table is ready',
    'linkUrl': '/user/consult/42',
    'read': false,
    'aggregateCount': 1,
  };
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {
    'list': [notification],
    'total': 1,
    'page': 1,
    'pageSize': 20,
    'hasMore': false,
  };
  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postedPath = path;
    return {...notification, 'read': true};
  }
}

class FakeConsult extends ConsultRepository {
  FakeConsult() : super(TestApi());
  List<ConsultMessage> messages = [
    const ConsultMessage(id: 1, senderType: 2, content: 'Welcome'),
  ];
  Object? loadError;
  Object? sendError;
  Completer<void>? loadGate;
  Completer<void>? sendGate;
  int loads = 0;
  int sends = 0;
  @override
  Future<ConsultThread> loadThread(int sessionId) async {
    loads++;
    final snapshot = [...messages];
    await loadGate?.future;
    if (loadError != null) throw loadError!;
    return ConsultThread(
      session: ConsultSession(
        id: sessionId,
        shopId: 100,
        shopName: 'Shop $sessionId',
        lastMessage: '',
        unread: 0,
      ),
      messages: snapshot,
    );
  }

  @override
  Future<ConsultMessage> sendMessage(int sessionId, String content) async {
    sends++;
    await sendGate?.future;
    if (sendError != null) throw sendError!;
    final message = ConsultMessage(id: 2, senderType: 1, content: content);
    messages = [...messages, message];
    return message;
  }
}

Widget localized(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

Future<void> mountChat(WidgetTester tester, FakeConsult repo) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  await tester.pumpWidget(
    localized(ConsultChatScreen(repository: repo, sessionId: 1)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'receives new merchant messages in the open chat and deduplicates snapshots',
    (tester) async {
      final repo = FakeConsult();
      await mountChat(tester, repo);
      repo.messages = [
        ...repo.messages,
        const ConsultMessage(id: 3, senderType: 2, content: 'A table is free'),
      ];
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('A table is free'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consult-msg-3')), findsOneWidget);
    },
  );

  testWidgets(
    'retries initial failures without enabling an unloaded composer',
    (tester) async {
      final repo = FakeConsult()..loadError = const ApiException('offline');
      await mountChat(tester, repo);
      expect(find.byKey(const Key('consult-chat-error')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('consult-send')))
            .onPressed,
        isNull,
      );
      repo.loadError = null;
      await tester.tap(find.byKey(const Key('consult-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
    },
  );

  testWidgets('keeps failed drafts and prevents duplicate sends', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakeConsult()
      ..sendGate = gate
      ..sendError = const ApiException('offline');
    await mountChat(tester, repo);
    await tester.enterText(
      find.byKey(const Key('consult-input')),
      'Keep this draft',
    );
    final send = tester
        .widget<FilledButton>(find.byKey(const Key('consult-send')))
        .onPressed!;
    send();
    send();
    await tester.pump();
    expect(repo.sends, 1);
    gate.complete();
    await tester.pumpAndSettle();
    repo.loadError = const ApiException('poll offline');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byKey(const Key('consult-send-error')), findsOneWidget);
  });

  testWidgets('a late poll cannot erase a successful send', (tester) async {
    final repo = FakeConsult();
    await mountChat(tester, repo);
    final gate = Completer<void>();
    repo.loadGate = gate;
    await tester.pump(const Duration(seconds: 3));
    await tester.enterText(
      find.byKey(const Key('consult-input')),
      'New message',
    );
    await tester.tap(find.byKey(const Key('consult-send')));
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consult-msg-2')), findsOneWidget);
    expect(find.text('New message'), findsOneWidget);
  });

  testWidgets('pauses requests in background and catches up on resume', (
    tester,
  ) async {
    final repo = FakeConsult();
    await mountChat(tester, repo);
    final initial = repo.loads;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 9));
    expect(repo.loads, initial);
    repo.messages = [
      ...repo.messages,
      const ConsultMessage(id: 4, senderType: 2, content: 'While away'),
    ];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('While away'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    final afterDispose = repo.loads;
    await tester.pump(const Duration(seconds: 9));
    expect(repo.loads, afterDispose);
  });

  testWidgets('ignores in-flight results after changing conversations', (
    tester,
  ) async {
    final repo = FakeConsult();
    await mountChat(tester, repo);
    final gate = Completer<void>();
    repo.loadGate = gate;
    await tester.pump(const Duration(seconds: 3));
    repo.loadGate = null;
    repo.messages = [
      const ConsultMessage(
        id: 9,
        senderType: 2,
        content: 'Different conversation',
      ),
    ];
    await tester.pumpWidget(
      localized(ConsultChatScreen(repository: repo, sessionId: 2)),
    );
    await tester.pumpAndSettle();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Different conversation'), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);
  });

  testWidgets('consult notification acknowledges and opens its session', (
    tester,
  ) async {
    final api = TestApi();
    int? sessionId;
    await tester.pumpWidget(
      localized(
        NotificationScreen(
          repository: NotificationRepository(api),
          onConsultTap: (id) => sessionId = id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Merchant replied to your chat'), findsOneWidget);
    await tester.tap(find.text('Merchant replied to your chat'));
    await tester.pumpAndSettle();
    expect(api.postedPath, '/api/c/v1/notifications/1/ack');
    expect(sessionId, 42);
  });
}
