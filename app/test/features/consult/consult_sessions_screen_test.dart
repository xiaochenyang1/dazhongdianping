import 'dart:async';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:dazhongdianping_app/features/consult/consult_sessions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'consult_repository_test.dart' show ConsultFakeApi;

class PagedConsult extends ConsultRepository {
  PagedConsult() : super(ConsultFakeApi());
  final calls = <({ConsultSessionCursor? cursor, bool unreadOnly})>[];
  Object? error;
  Completer<ConsultSessionPage>? gate;
  ConsultSessionPage result = page(20, more: true);
  @override
  Future<ConsultSessionPage> loadSessions({
    ConsultSessionCursor? cursor,
    bool unreadOnly = false,
    int? pageSize,
  }) async {
    calls.add((cursor: cursor, unreadOnly: unreadOnly));
    if (error != null) throw error!;
    if (gate != null) return gate!.future;
    return result;
  }
}

ConsultSessionPage page(int id, {bool more = false}) => ConsultSessionPage(
  sessions: [
    ConsultSession(
      id: id,
      shopId: id,
      shopName: 'Shop $id',
      lastMessage: 'Hello',
      unread: 1,
    ),
  ],
  hasMore: more,
  nextCursor: more
      ? ConsultSessionCursor(id: id, updatedAt: '2026-11-06T10:00:00')
      : null,
);
Widget host(PagedConsult repo) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
  home: ConsultSessionsScreen(repository: repo),
);
void main() {
  testWidgets('keeps a failed page, retries its cursor and navigates back', (
    tester,
  ) async {
    final repo = PagedConsult();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();
    repo.error = Exception('offline');
    await tester.tap(find.byKey(const Key('sessions-next')));
    await tester.pumpAndSettle();
    expect(find.text('Shop 20'), findsOneWidget);
    expect(find.byKey(const Key('consult-sessions-error')), findsOneWidget);
    repo.error = null;
    repo.result = page(10);
    await tester.tap(find.byKey(const Key('sessions-next')));
    await tester.pumpAndSettle();
    expect(repo.calls.last.cursor!.id, 20);
    expect(find.text('Shop 10'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('sessions-next')))
          .onPressed,
      isNull,
    );
    repo.result = page(20, more: true);
    await tester.tap(find.byKey(const Key('sessions-previous')));
    await tester.pumpAndSettle();
    expect(repo.calls.last.cursor, isNull);
    expect(find.text('Shop 20'), findsOneWidget);
  });
  testWidgets('filter invalidates a late page and resets pagination', (
    tester,
  ) async {
    final repo = PagedConsult();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();
    final pending = Completer<ConsultSessionPage>();
    repo.gate = pending;
    await tester.tap(find.byKey(const Key('sessions-next')));
    await tester.pump();
    repo.gate = null;
    repo.result = const ConsultSessionPage(sessions: []);
    await tester.tap(find.byKey(const Key('sessions-unread')));
    await tester.pumpAndSettle();
    expect(repo.calls.last.unreadOnly, isTrue);
    expect(repo.calls.last.cursor, isNull);
    pending.complete(page(10));
    await tester.pumpAndSettle();
    expect(find.text('No unread chats.'), findsOneWidget);
    expect(find.text('Shop 10'), findsNothing);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('sessions-previous')))
          .onPressed,
      isNull,
    );
  });
}
