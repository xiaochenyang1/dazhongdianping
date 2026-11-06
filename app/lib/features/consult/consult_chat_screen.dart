import 'dart:async';

import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:flutter/material.dart';

class ConsultChatScreen extends StatefulWidget {
  const ConsultChatScreen({
    super.key,
    required this.repository,
    required this.sessionId,
    this.title = '',
    this.pollInterval = const Duration(seconds: 3),
  });
  final ConsultRepository repository;
  final int sessionId;
  final String title;
  final Duration pollInterval;
  @override
  State<ConsultChatScreen> createState() => _ConsultChatScreenState();
}

class _ConsultChatScreenState extends State<ConsultChatScreen>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  List<ConsultMessage> _messages = [];
  Timer? _poller;
  bool _foreground = true;
  bool _loading = false;
  bool _loaded = false;
  bool _sending = false;
  bool _hasOlder = false;
  bool _historyLoading = false;
  int? _nextBeforeId;
  int _nextAfterId = 0;
  Object? _historyError;
  int _revision = 0;
  String _title = '';
  Object? _loadError;
  Object? _sendError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _title = widget.title;
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _load();
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant ConsultChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.repository != widget.repository) {
      ++_revision;
      _messages = [];
      _loaded = false;
      _loading = false;
      _sending = false;
      _hasOlder = false;
      _historyLoading = false;
      _historyError = null;
      _nextBeforeId = null;
      _nextAfterId = 0;
      _loadError = null;
      _sendError = null;
      _input.clear();
      _title = widget.title;
      _load();
    }
    if (oldWidget.pollInterval != widget.pollInterval) _startPolling();
  }

  void _startPolling() {
    _poller?.cancel();
    if (!_foreground) return;
    _poller = Timer.periodic(widget.pollInterval, (_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _startPolling();
    if (_foreground && (ModalRoute.of(context)?.isCurrent ?? true)) _load();
  }

  @override
  void dispose() {
    ++_revision;
    _poller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    super.dispose();
  }

  List<ConsultMessage> _merge(List<ConsultMessage> incoming) {
    // Polls and sends may finish in either order; an older snapshot cannot erase a sent message.
    final byId = {
      for (final message in _messages) message.id: message,
      for (final message in incoming) message.id: message,
    };
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> _load() async {
    if (_loading || !_foreground) return;
    final revision = _revision;
    setState(() => _loading = true);
    try {
      // A send response must not advance this read cursor: earlier incoming replies may
      // still be waiting between the previous poll and the newly sent message.
      for (var batch = 0; batch < 5; batch++) {
        final initial = !_loaded;
        final thread = await widget.repository.loadThread(
          widget.sessionId,
          afterId: initial ? null : _nextAfterId,
        );
        if (!mounted || revision != _revision) return;
        setState(() {
          _messages = _merge(thread.messages);
          if (initial) {
            _hasOlder = thread.hasMore;
            _nextBeforeId = thread.nextBeforeId;
          }
          _nextAfterId = thread.nextAfterId;
          _loaded = true;
          _loadError = null;
          if (thread.session.shopName.isNotEmpty) {
            _title = thread.session.shopName;
          }
        });
        if (initial ||
            !thread.hasMore ||
            !_foreground ||
            !(ModalRoute.of(context)?.isCurrent ?? true)) {
          break;
        }
      }
    } catch (error) {
      if (mounted && revision == _revision) setState(() => _loadError = error);
    } finally {
      if (mounted && revision == _revision) setState(() => _loading = false);
    }
  }

  Future<void> _loadOlder() async {
    if (_historyLoading || !_hasOlder || _nextBeforeId == null) return;
    final revision = _revision;
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final thread = await widget.repository.loadThread(
        widget.sessionId,
        beforeId: _nextBeforeId,
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        _messages = _merge(thread.messages);
        _hasOlder = thread.hasMore;
        _nextBeforeId = thread.nextBeforeId;
      });
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(() => _historyError = error);
      }
    } finally {
      if (mounted && revision == _revision) {
        setState(() => _historyLoading = false);
      }
    }
  }

  Future<void> _send() async {
    final content = _input.text.trim();
    if (_sending || !_loaded || content.isEmpty) return;
    final revision = _revision;
    final sessionId = widget.sessionId;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final message = await widget.repository.sendMessage(sessionId, content);
      if (!mounted || revision != _revision) return;
      setState(() {
        _messages = _merge([message]);
        _input.clear();
      });
    } catch (error) {
      if (mounted && revision == _revision) setState(() => _sendError = error);
    } finally {
      if (mounted && revision == _revision) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title.isEmpty ? strings.myConsultTitle : _title),
        actions: [
          IconButton(
            key: const Key('consult-refresh'),
            tooltip: strings.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.consultLoadFailed(_loadError!),
                      key: const Key('consult-chat-error'),
                    ),
                  ),
                  TextButton(
                    key: const Key('consult-retry'),
                    onPressed: _loading ? null : _load,
                    child: Text(strings.retry),
                  ),
                ],
              ),
            ),
          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                strings.consultSendFailed(_sendError!),
                key: const Key('consult-send-error'),
              ),
            ),
          if (_hasOlder)
            TextButton(
              key: const Key('consult-load-older'),
              onPressed: _historyLoading ? null : _loadOlder,
              child: Text(
                _historyLoading ? strings.loading : strings.consultLoadOlder,
              ),
            ),
          if (_historyError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                strings.loadMoreFailed(_historyError!),
                key: const Key('consult-history-error'),
              ),
            ),
          Expanded(
            child: !_loaded && _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(_loaded ? strings.consultMessagesEmpty : ''),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      final mine = message.senderType == 1;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          key: Key('consult-msg-${message.id}'),
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mine
                                      ? strings.consultYou
                                      : strings.consultMerchant,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(message.content),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('consult-input'),
                      controller: _input,
                      enabled: _loaded && !_sending,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: strings.consultInputHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('consult-send'),
                    onPressed: !_loaded || _sending ? null : _send,
                    child: Text(
                      _sending ? strings.submitting : strings.consultSend,
                    ),
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
