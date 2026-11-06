import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/creator/creator_repository.dart';
import 'package:flutter/material.dart';

class CreatorSubmissionScreen extends StatefulWidget {
  const CreatorSubmissionScreen({
    super.key,
    required this.repository,
    required this.task,
  });
  final CreatorRepository repository;
  final CreatorTask task;
  @override
  State<CreatorSubmissionScreen> createState() =>
      _CreatorSubmissionScreenState();
}

class _CreatorSubmissionScreenState extends State<CreatorSubmissionScreen> {
  late String _type;
  late TextEditingController _note;
  List<CreatorEvidence> _evidence = [];
  int? _selectedId;
  int _page = 0;
  int _revision = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _sending = false;
  Object? _error;
  bool _evidenceFailed = false;
  bool _lastReset = true;

  @override
  void initState() {
    super.initState();
    _type = widget.task.evidenceType == 'post' ? 'post' : 'review';
    _note = TextEditingController(text: widget.task.submissionNote);
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant CreatorSubmissionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.task.id != widget.task.id) {
      _type = widget.task.evidenceType == 'post' ? 'post' : 'review';
      _note.text = widget.task.submissionNote;
      _sending = false;
      _load(reset: true);
    }
  }

  Future<void> _load({required bool reset}) async {
    final current = ++_revision;
    final target = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
      _evidenceFailed = false;
      _lastReset = reset;
      if (reset) {
        _evidence = [];
        _selectedId = null;
        _page = 0;
        _hasMore = false;
      }
    });
    try {
      final result = await widget.repository.evidence(_type, page: target);
      if (!mounted || current != _revision) return;
      setState(() {
        final known = _evidence.map((item) => item.id).toSet();
        _evidence = [
          ..._evidence,
          ...result.items.where((item) => known.add(item.id)),
        ];
        _page = target;
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (mounted && current == _revision) {
        setState(() {
          _error = error;
          _evidenceFailed = true;
        });
      }
    } finally {
      if (mounted && current == _revision) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_loading || _sending || _selectedId == null || _note.text.length > 1000) {
      return;
    }
    final current = _revision;
    setState(() {
      _sending = true;
      _error = null;
      _evidenceFailed = false;
    });
    try {
      await widget.repository.submit(
        widget.task.id,
        type: _type,
        evidenceId: _selectedId!,
        note: _note.text,
      );
      if (mounted && current == _revision) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted && current == _revision) setState(() => _error = error);
    } finally {
      if (mounted && current == _revision) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _revision++;
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.creatorSubmit)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.task.description),
            Text('${widget.task.rewardPoints} ${strings.creatorPoints}'),
            if (widget.task.reviewNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(widget.task.reviewNote),
              ),
            const SizedBox(height: 20),
            InputDecorator(
              decoration: InputDecoration(labelText: strings.creatorWorkType),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('creator-evidence-type'),
                  value: _type,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'review',
                      child: Text(strings.creatorReview),
                    ),
                    DropdownMenuItem(
                      value: 'post',
                      child: Text(strings.creatorPost),
                    ),
                  ],
                  onChanged: _sending
                      ? null
                      : (value) {
                          if (value == null || value == _type) return;
                          setState(() => _type = value);
                          _load(reset: true);
                        },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading || _sending) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${strings.creatorFailed}\n$_error',
                  key: const Key('creator-submission-error'),
                ),
              ),
            if (_evidenceFailed && !_sending)
              TextButton(
                key: const Key('creator-evidence-retry'),
                onPressed: _loading ? null : () => _load(reset: _lastReset),
                child: Text(strings.creatorRefresh),
              ),
            InputDecorator(
              decoration: InputDecoration(labelText: strings.creatorChooseWork),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  key: const Key('creator-evidence-select'),
                  value: _selectedId,
                  isExpanded: true,
                  hint: Text(
                    strings.creatorChooseWork,
                    overflow: TextOverflow.ellipsis,
                  ),
                  items: [
                    for (final item in _evidence)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _loading || _sending
                      ? null
                      : (value) => setState(() => _selectedId = value),
                ),
              ),
            ),
            if (!_loading && _error == null && _evidence.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(strings.creatorNoWork),
              ),
            if (_hasMore)
              TextButton(
                key: const Key('creator-evidence-more'),
                onPressed: _loading || _sending
                    ? null
                    : () => _load(reset: false),
                child: Text(strings.creatorMoreWork),
              ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('creator-submission-note'),
              controller: _note,
              enabled: !_sending,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: strings.creatorNote),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('creator-submit-work'),
              onPressed: _loading || _sending || _selectedId == null
                  ? null
                  : _submit,
              child: Text(strings.creatorSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
