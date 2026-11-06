import 'dart:async';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/creator/creator_repository.dart';
import 'package:dazhongdianping_app/features/creator/creator_submission_screen.dart';
import 'package:dazhongdianping_app/features/creator/creator_tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'creator_repository_test.dart' show CreatorFakeApi;

CreatorTask task({
  int status = 1,
  int id = 10,
  String? type,
  String note = '',
  String reason = '',
}) => CreatorTask(
  id: id,
  title: 'Task $id',
  description: 'Original task requirements',
  rewardPoints: 20,
  claimStatus: status,
  evidenceType: type,
  submissionNote: note,
  reviewNote: reason,
);
CreatorPage<CreatorTask> tasks(CreatorTask item, {bool more = false}) =>
    CreatorPage(items: [item], hasMore: more);
CreatorPage<CreatorEvidence> work({int id = 81, bool more = false}) =>
    CreatorPage(
      items: [CreatorEvidence(id: id, title: 'Work $id')],
      hasMore: more,
    );

class CreatorStub extends CreatorRepository {
  CreatorStub() : super(CreatorFakeApi());
  CreatorPage<CreatorTask> taskResult = tasks(task());
  CreatorPage<CreatorEvidence> workResult = work();
  Object? listError, workError, submitError;
  Completer<CreatorPage<CreatorTask>>? listGate;
  Completer<CreatorPage<CreatorEvidence>>? workGate;
  Completer<void>? claimGate, submitGate;
  final listCalls = <int>[];
  final workCalls = <({String type, int page})>[];
  final claimCalls = <int>[];
  final submitCalls = <({int id, String type, int evidenceId, String note})>[];

  @override
  Future<CreatorPage<CreatorTask>> load({int page = 1}) async {
    listCalls.add(page);
    if (listError != null) throw listError!;
    return listGate == null ? taskResult : listGate!.future;
  }

  @override
  Future<CreatorPage<CreatorEvidence>> evidence(
    String type, {
    int page = 1,
  }) async {
    workCalls.add((type: type, page: page));
    if (workError != null) throw workError!;
    return workGate == null ? workResult : workGate!.future;
  }

  @override
  Future<void> claim(int id) async {
    claimCalls.add(id);
    if (claimGate != null) await claimGate!.future;
  }

  @override
  Future<void> submit(
    int id, {
    required String type,
    required int evidenceId,
    required String note,
  }) async {
    submitCalls.add((id: id, type: type, evidenceId: evidenceId, note: note));
    if (submitError != null) throw submitError!;
    if (submitGate != null) await submitGate!.future;
  }
}

Widget host(
  CreatorStub repository, {
  CreatorTask? submission,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: submission == null
      ? CreatorTasksScreen(repository: repository)
      : CreatorSubmissionScreen(repository: repository, task: submission),
);
Future<void> mount(
  WidgetTester tester,
  CreatorStub repository, {
  CreatorTask? submission,
  Locale locale = const Locale('en'),
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    host(repository, submission: submission, locale: locale),
  );
  await tester.pumpAndSettle();
}

Finder key(String value) => find.byKey(Key(value));
Future<void> choose(WidgetTester tester, {int id = 81}) async {
  await tester.tap(key('creator-evidence-select'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Work $id').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'distinguishes claimed, pending, rejected and awarded tasks without self-award controls',
    (tester) async {
      final repo = CreatorStub()
        ..taskResult = CreatorPage(
          items: [
            task(),
            task(status: 3, id: 11),
            task(status: 4, id: 12, reason: 'Add a menu photo'),
            task(status: 2, id: 13),
          ],
        );
      await mount(tester, repo);
      expect(find.text('Claimed'), findsOneWidget);
      expect(find.text('Awaiting review'), findsOneWidget);
      expect(find.text('Points awarded'), findsOneWidget);
      expect(find.text('Add a menu photo'), findsOneWidget);
      expect(key('creator-submit-10'), findsOneWidget);
      expect(key('creator-submit-12'), findsOneWidget);
      expect(key('creator-submit-11'), findsNothing);
      expect(key('creator-submit-13'), findsNothing);
      expect(find.text('Complete'), findsNothing);
    },
  );

  testWidgets(
    'prevents duplicate claims and keeps claimed status if refresh fails',
    (tester) async {
      final repo = CreatorStub()..taskResult = tasks(task(status: 0));
      await mount(tester, repo);
      final pending = Completer<void>();
      repo.claimGate = pending;
      await tester.tap(key('creator-claim-10'));
      await tester.pump();
      await tester.tap(key('creator-claim-10'));
      await tester.pump();
      expect(repo.claimCalls, [10]);
      repo.listError = Exception('refresh offline');
      pending.complete();
      await tester.pumpAndSettle();
      expect(key('creator-submit-10'), findsOneWidget);
      expect(key('creator-claim-10'), findsNothing);
      expect(find.textContaining('refresh offline'), findsOneWidget);
    },
  );

  testWidgets('submits work once and returns to the pending task', (
    tester,
  ) async {
    final repo = CreatorStub();
    await mount(tester, repo);
    await tester.tap(key('creator-submit-10'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(key('creator-submit-work')).onPressed,
      isNull,
    );
    await choose(tester);
    await tester.enterText(key('creator-submission-note'), 'Menu included');
    final pending = Completer<void>();
    repo.submitGate = pending;
    await tester.tap(key('creator-submit-work'));
    await tester.pump();
    await tester.tap(key('creator-submit-work'));
    await tester.pump();
    expect(repo.submitCalls, [
      (id: 10, type: 'review', evidenceId: 81, note: 'Menu included'),
    ]);
    repo.taskResult = tasks(task(status: 3));
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CreatorSubmissionScreen), findsNothing);
    expect(find.text('Awaiting review'), findsOneWidget);
  });

  testWidgets(
    'preserves rejected submission text and selected work after submission failure',
    (tester) async {
      final repo = CreatorStub()..submitError = Exception('submission offline');
      await mount(
        tester,
        repo,
        submission: task(
          status: 4,
          type: 'post',
          note: 'Original explanation',
          reason: 'Add a photo',
        ),
      );
      expect(repo.workCalls.last.type, 'post');
      expect(find.text('Add a photo'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(key('creator-submission-note'))
            .controller!
            .text,
        'Original explanation',
      );
      await choose(tester);
      await tester.enterText(key('creator-submission-note'), 'Photo added');
      await tester.tap(key('creator-submit-work'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<int>>(key('creator-evidence-select'))
            .value,
        81,
      );
      expect(
        tester
            .widget<TextField>(key('creator-submission-note'))
            .controller!
            .text,
        'Photo added',
      );
      expect(find.textContaining('submission offline'), findsOneWidget);
      expect(key('creator-evidence-retry'), findsNothing);
      expect(
        tester.widget<FilledButton>(key('creator-submit-work')).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'retries the failed evidence page without losing work selection',
    (tester) async {
      final repo = CreatorStub()..workResult = work(more: true);
      await mount(tester, repo, submission: task());
      await choose(tester);
      repo.workError = Exception('page offline');
      await tester.tap(key('creator-evidence-more'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<int>>(key('creator-evidence-select'))
            .value,
        81,
      );
      repo.workError = null;
      repo.workResult = const CreatorPage(
        items: [
          CreatorEvidence(id: 81, title: 'Work 81'),
          CreatorEvidence(id: 82, title: 'Work 82'),
        ],
      );
      await tester.tap(key('creator-evidence-retry'));
      await tester.pumpAndSettle();
      expect(repo.workCalls.map((call) => call.page), [1, 2, 2]);
      final dropdown = tester.widget<DropdownButton<int>>(
        key('creator-evidence-select'),
      );
      expect(dropdown.items, hasLength(2));
      expect(dropdown.value, 81);
    },
  );

  testWidgets('invalidates a late evidence page after changing the work type', (
    tester,
  ) async {
    final repo = CreatorStub()..workResult = work(more: true);
    await mount(tester, repo, submission: task());
    await choose(tester);
    final pending = Completer<CreatorPage<CreatorEvidence>>();
    repo.workGate = pending;
    await tester.tap(key('creator-evidence-more'));
    await tester.pump();
    repo.workGate = null;
    repo.workResult = work(id: 90);
    await tester.tap(key('creator-evidence-type'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Post').last);
    await tester.pumpAndSettle();
    pending.complete(work(id: 82));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButton<int>>(
      key('creator-evidence-select'),
    );
    expect(dropdown.value, isNull);
    expect(dropdown.items!.single.value, 90);
    expect(repo.workCalls.last, (type: 'post', page: 1));
    expect(
      tester.widget<FilledButton>(key('creator-submit-work')).onPressed,
      isNull,
    );
  });

  testWidgets(
    'retries task pages and resets pagination when the repository changes',
    (tester) async {
      final repo = CreatorStub()..taskResult = tasks(task(id: 20), more: true);
      await mount(tester, repo);
      repo.listError = Exception('list offline');
      await tester.tap(key('creator-next'));
      await tester.pumpAndSettle();
      expect(find.text('Task 20'), findsOneWidget);
      repo.listError = null;
      repo.taskResult = tasks(task(id: 10));
      await tester.tap(key('creator-next'));
      await tester.pumpAndSettle();
      expect(repo.listCalls, [1, 2, 2]);
      expect(find.text('Task 10'), findsOneWidget);
      final pending = Completer<CreatorPage<CreatorTask>>();
      repo.listGate = pending;
      await tester.tap(key('creator-previous'));
      await tester.pump();
      final replacement = CreatorStub()
        ..taskResult = const CreatorPage(items: []);
      await tester.pumpWidget(host(replacement));
      await tester.pumpAndSettle();
      pending.complete(tasks(task(id: 99)));
      await tester.pumpAndSettle();
      expect(find.text('Task 99'), findsNothing);
      expect(find.text('No tasks yet.'), findsOneWidget);
      expect(
        tester.widget<TextButton>(key('creator-previous')).onPressed,
        isNull,
      );
    },
  );

  testWidgets('ignores a late submission when the repository changes', (
    tester,
  ) async {
    final repo = CreatorStub();
    await mount(tester, repo, submission: task());
    await choose(tester);
    await tester.enterText(key('creator-submission-note'), 'Private note');
    final pending = Completer<void>();
    repo.submitGate = pending;
    await tester.tap(key('creator-submit-work'));
    await tester.pump();
    final replacement = CreatorStub()..workResult = work(id: 90);
    await tester.pumpWidget(host(replacement, submission: task()));
    await tester.pumpAndSettle();
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CreatorSubmissionScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(key('creator-submission-note')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<DropdownButton<int>>(key('creator-evidence-select')).value,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows Traditional Chinese instructions and retries the initial empty evidence request',
    (tester) async {
      final repo = CreatorStub()..workError = Exception('offline');
      await mount(
        tester,
        repo,
        submission: task(),
        locale: const Locale('zh', 'TW'),
      );
      expect(find.text('提交成果'), findsNWidgets(2));
      repo.workError = null;
      repo.workResult = const CreatorPage(items: []);
      await tester.tap(key('creator-evidence-retry'));
      await tester.pumpAndSettle();
      expect(repo.workCalls.map((call) => call.page), [1, 1]);
      expect(find.textContaining('沒有可提交的已發布作品'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(key('creator-submit-work')).onPressed,
        isNull,
      );
    },
  );
}
