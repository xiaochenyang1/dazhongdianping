import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/creator/creator_repository.dart';
import 'package:dazhongdianping_app/features/creator/creator_submission_screen.dart';
import 'package:flutter/material.dart';

class CreatorTasksScreen extends StatefulWidget {
  const CreatorTasksScreen({super.key, required this.repository});

  final CreatorRepository repository;

  @override
  State<CreatorTasksScreen> createState() => _CreatorTasksScreenState();
}

class _CreatorTasksScreenState extends State<CreatorTasksScreen> {
  List<CreatorTask> _tasks = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _acting = false;
  Object? _error;
  int _scope = 0;
  int _revision = 0;
  final _scroll = ScrollController();
  bool get _busy => _loading || _acting;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  @override
  void didUpdateWidget(covariant CreatorTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _scope++;
      _tasks = [];
      _page = 1;
      _hasMore = false;
      _acting = false;
      _load(1);
    }
  }

  Future<void> _load(int page) async {
    final current = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.load(page: page);
      if (!mounted || current != _revision) return;
      setState(() {
        _tasks = result.items;
        _hasMore = result.hasMore;
        _page = page;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (error) {
      if (mounted && current == _revision) setState(() => _error = error);
    } finally {
      if (mounted && current == _revision) setState(() => _loading = false);
    }
  }

  void _updateStatus(int id, int status) {
    setState(
      () => _tasks = _tasks
          .map((task) => task.id == id ? task.withStatus(status) : task)
          .toList(),
    );
  }

  Future<void> _claim(CreatorTask task) async {
    if (_busy) return;
    final current = _scope;
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await widget.repository.claim(task.id);
      if (!mounted || current != _scope) return;
      _updateStatus(task.id, 1);
      await _load(_page);
    } catch (error) {
      if (mounted && current == _scope) setState(() => _error = error);
    } finally {
      if (mounted && current == _scope) setState(() => _acting = false);
    }
  }

  Future<void> _submit(CreatorTask task) async {
    if (_busy) return;
    final current = _scope;
    setState(() => _acting = true);
    try {
      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreatorSubmissionScreen(
            repository: widget.repository,
            task: task,
          ),
        ),
      );
      if (!mounted || current != _scope) return;
      if (submitted == true) {
        _updateStatus(task.id, 3);
        await _load(_page);
      }
    } finally {
      if (mounted && current == _scope) setState(() => _acting = false);
    }
  }

  @override
  void dispose() {
    _scope++;
    _revision++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final statuses = {
      1: strings.creatorClaimed,
      2: strings.creatorAwarded,
      3: strings.creatorPending,
      4: strings.creatorRejected,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.creatorTasksTitle),
        actions: [
          IconButton(
            key: const Key('creator-refresh'),
            tooltip: strings.creatorRefresh,
            onPressed: _busy ? null : () => _load(_page),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading || _acting) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${strings.creatorFailed}\n$_error',
                key: const Key('creator-error'),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _busy ? Future<void>.value() : _load(1),
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(strings.creatorSummary),
                  const SizedBox(height: 12),
                  if (!_loading && _error == null && _tasks.isEmpty)
                    Text(strings.creatorEmpty),
                  for (final task in _tasks)
                    Card(
                      key: Key('creator-task-${task.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(task.description),
                            const SizedBox(height: 8),
                            Text(
                              '${task.rewardPoints} ${strings.creatorPoints}',
                            ),
                            if (statuses.containsKey(task.claimStatus))
                              Text(statuses[task.claimStatus]!),
                            if (task.claimStatus == 4 &&
                                task.reviewNote.isNotEmpty)
                              Text(task.reviewNote),
                            if (task.claimStatus == 0)
                              TextButton(
                                key: Key('creator-claim-${task.id}'),
                                onPressed: _busy ? null : () => _claim(task),
                                child: Text(strings.creatorClaim),
                              ),
                            if (task.claimStatus == 1 || task.claimStatus == 4)
                              TextButton(
                                key: Key('creator-submit-${task.id}'),
                                onPressed: _busy ? null : () => _submit(task),
                                child: Text(strings.creatorSubmit),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    key: const Key('creator-previous'),
                    onPressed: _busy || _page <= 1
                        ? null
                        : () => _load(_page - 1),
                    child: Text(strings.creatorPrevious),
                  ),
                  Text('$_page'),
                  TextButton(
                    key: const Key('creator-next'),
                    onPressed: _busy || !_hasMore
                        ? null
                        : () => _load(_page + 1),
                    child: Text(strings.creatorNext),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
