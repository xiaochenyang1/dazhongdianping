import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/ticket/ticket_detail_screen.dart';
import 'package:dazhongdianping_app/features/ticket/ticket_repository.dart';
import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.repository});
  final TicketRepository repository;
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _content = TextEditingController();
  final _opening = <int>{};
  List<SupportTicket> _tickets = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _creating = false;
  bool _hasMore = false;
  int _page = 0;
  int _revision = 0;
  Object? _loadError;
  Object? _createError;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _subject.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && (_loadingMore || !_hasMore))) return;
    final revision = reset ? ++_revision : _revision;
    setState(() {
      _loadError = null;
      if (reset) {
        _loading = true;
        _loadingMore = false;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await widget.repository.loadPage(
        page: reset ? 1 : _page + 1,
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        final known = reset ? <int>{} : _tickets.map((t) => t.id).toSet();
        _tickets = [
          if (!reset) ..._tickets,
          ...result.items.where((t) => known.add(t.id)),
        ];
        _page = result.page;
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (mounted && revision == _revision) setState(() => _loadError = error);
    } finally {
      if (mounted && revision == _revision) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _open(int id) async {
    if (!_opening.add(id)) return;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              TicketDetailScreen(repository: widget.repository, ticketId: id),
        ),
      );
      if (mounted) await _load(reset: true);
    } finally {
      _opening.remove(id);
    }
  }

  Future<void> _create() async {
    if (_creating || !_form.currentState!.validate()) return;
    setState(() {
      _creating = true;
      _createError = null;
    });
    SupportTicket? created;
    try {
      final ticket = await widget.repository.create(
        subject: _subject.text.trim(),
        content: _content.text.trim(),
      );
      if (!mounted) return;
      created = ticket;
      _subject.clear();
      _content.clear();
      // Discard list responses that began before this successful write.
      ++_revision;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _tickets = [ticket, ..._tickets.where((t) => t.id != ticket.id)];
      });
    } catch (error) {
      if (mounted) setState(() => _createError = error);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
    if (mounted && created != null) await _open(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.myTicketsTitle),
        actions: [
          IconButton(
            key: const Key('tickets-refresh'),
            tooltip: strings.refresh,
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('ticket-subject'),
                    controller: _subject,
                    enabled: !_creating,
                    maxLength: 128,
                    decoration: InputDecoration(
                      labelText: strings.ticketSubject,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? strings.ticketSubjectRequired
                        : null,
                  ),
                  TextFormField(
                    key: const Key('ticket-content'),
                    controller: _content,
                    enabled: !_creating,
                    maxLength: 2000,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: strings.ticketContent,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? strings.ticketContentRequired
                        : null,
                  ),
                  if (_createError != null)
                    Text(
                      strings.actionFailed(
                        localizeTicketError(strings, _createError!),
                      ),
                      key: const Key('ticket-create-error'),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      key: const Key('ticket-create'),
                      onPressed: _creating ? null : _create,
                      child: Text(
                        _creating ? strings.submitting : strings.ticketSubmit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_loadError != null) ...[
              Text(
                strings.ticketsLoadFailed(
                  localizeTicketError(strings, _loadError!),
                ),
              ),
              TextButton(
                key: const Key('tickets-retry'),
                onPressed: _loading ? null : () => _load(reset: true),
                child: Text(strings.retry),
              ),
            ],
            if (!_loading && _loadError == null && _tickets.isEmpty)
              Text(strings.ticketsEmpty, key: const Key('tickets-empty')),
            for (final ticket in _tickets)
              ListTile(
                key: Key('ticket-${ticket.id}'),
                title: Text(ticket.subject),
                subtitle: Text(
                  '${strings.ticketStatusLabel(ticket.status)}\n${ticket.content}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(ticket.id),
              ),
            if (_hasMore)
              TextButton(
                key: const Key('tickets-more'),
                onPressed: _loading || _loadingMore ? null : () => _load(),
                child: Text(_loadingMore ? strings.loading : strings.loadMore),
              ),
          ],
        ),
      ),
    );
  }
}
