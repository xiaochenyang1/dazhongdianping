import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/ticket/ticket_detail_screen.dart';
import 'package:dazhongdianping_app/features/ticket/ticket_repository.dart';
import 'package:dazhongdianping_app/features/ticket/tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

SupportTicket ticket({
  int id = 1,
  int status = 2,
  List<TicketMessage>? messages,
}) => SupportTicket(
  id: id,
  subject: 'Booking help $id',
  content: 'Please check my booking',
  status: status,
  statusText: '处理中',
  shopId: 0,
  messages:
      messages ??
      const [
        TicketMessage(id: 1, content: 'We found your booking', senderType: 3),
      ],
);

class TicketApi implements JsonApi {
  String? path;
  Map<String, Object?>? query;
  Map<String, dynamic> response = {};
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
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      response;
}

class FakeTickets extends TicketRepository {
  FakeTickets() : super(TicketApi());
  SupportTicket current = ticket();
  Object? listError;
  Object? detailError;
  Object? createError;
  Object? replyError;
  Completer<void>? createGate;
  Completer<void>? replyGate;
  Completer<TicketPage>? pageGate;
  int creates = 0;
  int replies = 0;
  int details = 0;
  final pages = <int>[];

  @override
  Future<TicketPage> loadPage({int page = 1, int pageSize = 12}) async {
    pages.add(page);
    if (listError != null) throw listError!;
    if (page > 1 && pageGate != null) return pageGate!.future;
    return TicketPage(
      items: [ticket(id: page)],
      page: page,
      hasMore: page == 1,
    );
  }

  @override
  Future<SupportTicket> detail(int id) async {
    details++;
    if (detailError != null) throw detailError!;
    return current;
  }

  @override
  Future<SupportTicket> create({
    required String subject,
    required String content,
    int shopId = 0,
  }) async {
    creates++;
    await createGate?.future;
    if (createError != null) throw createError!;
    return current;
  }

  @override
  Future<SupportTicket> reply(int id, String content) async {
    replies++;
    await replyGate?.future;
    if (replyError != null) throw replyError!;
    current = ticket(
      messages: [
        ...current.messages,
        TicketMessage(id: 2, content: content, senderType: 1),
      ],
    );
    return current;
  }
}

Widget app(Widget home) => MaterialApp(
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

Future<void> fillTicket(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('ticket-subject')),
    'Payment question',
  );
  await tester.enterText(
    find.byKey(const Key('ticket-content')),
    'Please help',
  );
}

void main() {
  test(
    'ticket repository preserves pagination and message timestamps',
    () async {
      final api = TicketApi()
        ..response = {
          'list': [
            {
              'id': 9,
              'status': 4,
              'messages': [
                {
                  'id': 12,
                  'senderType': 3,
                  'content': 'Closed',
                  'createdAt': '2026-10-29T12:00:00',
                },
              ],
            },
          ],
          'page': 2,
          'hasMore': true,
          'total': 30,
        };
      final page = await TicketRepository(api).loadPage(page: 2);
      expect(api.query, {'page': 2, 'pageSize': 12});
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
      expect(page.items.single.canReply, isFalse);
      expect(
        page.items.single.messages.single.createdAt,
        '2026-10-29T12:00:00',
      );
    },
  );

  testWidgets('ticket creation validates empty fields', (tester) async {
    final repo = FakeTickets();
    await tester.pumpWidget(app(TicketsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-create')));
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(find.text('Enter a subject.'), findsOneWidget);
    expect(find.text('Enter your message.'), findsOneWidget);
  });

  testWidgets('creation guards rapid clicks and opens the new ticket', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakeTickets()..createGate = gate;
    await tester.pumpWidget(app(TicketsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await fillTicket(tester);
    final submit = tester
        .widget<FilledButton>(find.byKey(const Key('ticket-create')))
        .onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(repo.creates, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TicketDetailScreen), findsOneWidget);
    expect(find.text('We found your booking'), findsOneWidget);
    expect(repo.details, 1);
  });

  testWidgets('failed creation keeps the draft and can be retried', (
    tester,
  ) async {
    final repo = FakeTickets()..createError = const ApiException('offline');
    await tester.pumpWidget(app(TicketsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await fillTicket(tester);
    await tester.tap(find.byKey(const Key('ticket-create')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-create-error')), findsOneWidget);
    expect(find.text('Payment question'), findsOneWidget);
    expect(find.text('Please help'), findsOneWidget);
    repo.createError = null;
    await tester.tap(find.byKey(const Key('ticket-create')));
    await tester.pumpAndSettle();
    expect(find.byType(TicketDetailScreen), findsOneWidget);
    expect(repo.creates, 2);
  });

  testWidgets('list pagination discards stale pages after refresh', (
    tester,
  ) async {
    final gate = Completer<TicketPage>();
    final repo = FakeTickets()..pageGate = gate;
    await tester.pumpWidget(app(TicketsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('tickets-more')));
    await tester.tap(find.byKey(const Key('tickets-more')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tickets-refresh')));
    await tester.pumpAndSettle();
    gate.complete(TicketPage(items: [ticket(id: 99)], page: 2, hasMore: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-99')), findsNothing);
    expect(repo.pages, [1, 2, 1]);
  });

  testWidgets(
    'list failure is retryable and old tickets survive refresh failure',
    (tester) async {
      final repo = FakeTickets()..listError = const ApiException('offline');
      await tester.pumpWidget(app(TicketsScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tickets-empty')), findsNothing);
      repo.listError = null;
      await tester.ensureVisible(find.byKey(const Key('tickets-retry')));
      await tester.tap(find.byKey(const Key('tickets-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-1')), findsOneWidget);
      repo.listError = const ApiException('offline');
      await tester.tap(find.byKey(const Key('tickets-refresh')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ticket-1')), findsOneWidget);
    },
  );

  testWidgets('user reads the support response and replies only once', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakeTickets()..replyGate = gate;
    await tester.pumpWidget(
      app(TicketDetailScreen(repository: repo, ticketId: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('We found your booking'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('ticket-reply-input')),
      'Thank you',
    );
    final send = tester
        .widget<FilledButton>(find.byKey(const Key('ticket-reply-send')))
        .onPressed!;
    send();
    send();
    await tester.pump();
    expect(repo.replies, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-message-2')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('ticket-reply-input')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets(
    'failed reply keeps its draft, then updates closed status after a conflict',
    (tester) async {
      final repo = FakeTickets()..replyError = const ApiException('offline');
      await tester.pumpWidget(
        app(TicketDetailScreen(repository: repo, ticketId: 1)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('ticket-reply-input')),
        'Still need help',
      );
      await tester.tap(find.byKey(const Key('ticket-reply-send')));
      await tester.pumpAndSettle();
      expect(find.text('Still need help'), findsOneWidget);
      repo.replyError = const ApiException('工单当前状态不可回复', statusCode: 409);
      repo.current = ticket(status: 4);
      await tester.tap(find.byKey(const Key('ticket-reply-send')));
      await tester.pumpAndSettle();
      expect(find.text('Closed'), findsOneWidget);
      expect(find.byKey(const Key('ticket-reply-send')), findsNothing);
      expect(find.byKey(const Key('ticket-reply-unavailable')), findsOneWidget);
    },
  );

  testWidgets('resolved ticket is read only and detail load can be retried', (
    tester,
  ) async {
    final repo = FakeTickets()
      ..current = ticket(status: 3)
      ..detailError = const ApiException('offline');
    await tester.pumpWidget(
      app(TicketDetailScreen(repository: repo, ticketId: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-detail-error')), findsOneWidget);
    repo.detailError = null;
    await tester.tap(find.byKey(const Key('ticket-detail-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.byKey(const Key('ticket-reply-input')), findsNothing);
  });
}
