import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/consult/consult_chat_screen.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:flutter/material.dart';

/// 我的咨询：有界分页，翻页失败时保留当前页。
class ConsultSessionsScreen extends StatefulWidget {
  const ConsultSessionsScreen({super.key, required this.repository});
  final ConsultRepository repository;
  @override
  State<ConsultSessionsScreen> createState() => _ConsultSessionsScreenState();
}

class _ConsultSessionsScreenState extends State<ConsultSessionsScreen> {
  List<ConsultSession> _sessions = [];
  List<ConsultSessionCursor?> _cursors = [null];
  int _page = 0;
  int _revision = 0;
  bool _loading = true;
  bool _unreadOnly = false;
  bool _hasMore = false;
  Object? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  @override
  void didUpdateWidget(covariant ConsultSessionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) _reset();
  }

  void _reset() {
    _cursors = [null];
    _page = 0;
    _sessions = [];
    _hasMore = false;
    _load(0);
  }

  Future<void> _load(int page) async {
    final current = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.loadSessions(
        cursor: _cursors[page],
        unreadOnly: _unreadOnly,
      );
      if (!mounted || current != _revision) return;
      setState(() {
        _sessions = result.sessions;
        _page = page;
        _hasMore = result.hasMore;
        _cursors = _cursors.take(page + 1).toList();
        if (result.hasMore && result.nextCursor != null) {
          _cursors.add(result.nextCursor);
        }
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
    } catch (error) {
      if (mounted && current == _revision) setState(() => _error = error);
    } finally {
      if (mounted && current == _revision) setState(() => _loading = false);
    }
  }

  Future<void> _open(ConsultSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultChatScreen(
          repository: widget.repository,
          sessionId: session.id,
          title: session.shopName,
        ),
      ),
    );
    if (mounted) await _load(0);
  }

  @override
  void dispose() {
    _revision++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myConsultTitle)),
      body: Column(
        children: [
          CheckboxListTile(
            key: const Key('sessions-unread'),
            title: Text(strings.consultUnreadOnly),
            value: _unreadOnly,
            onChanged: (value) {
              setState(() => _unreadOnly = value ?? false);
              _reset();
            },
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                strings.consultLoadFailed(_error!),
                key: const Key('consult-sessions-error'),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(0),
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_loading && _error == null && _sessions.isEmpty)
                    Text(
                      _unreadOnly
                          ? strings.consultNoUnread
                          : strings.consultSessionsEmpty,
                      key: const Key('consult-sessions-empty'),
                    ),
                  for (final session in _sessions)
                    Card(
                      key: Key('consult-session-${session.id}'),
                      child: ListTile(
                        title: Text(session.shopName),
                        subtitle: Text(
                          session.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: session.unread > 0
                            ? Badge(label: Text('${session.unread}'))
                            : const Icon(Icons.chevron_right),
                        onTap: () => _open(session),
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
                    key: const Key('sessions-previous'),
                    onPressed: _loading || _page == 0
                        ? null
                        : () => _load(_page - 1),
                    child: Text(strings.consultPreviousPage),
                  ),
                  Text('${_page + 1}'),
                  TextButton(
                    key: const Key('sessions-next'),
                    onPressed: _loading || !_hasMore
                        ? null
                        : () => _load(_page + 1),
                    child: Text(strings.consultNextPage),
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
