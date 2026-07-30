import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/message/message_error_localizer.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:flutter/material.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({
    super.key,
    required this.repository,
    required this.currentUserId,
  });
  final MessageRepository repository;
  final int currentUserId;
  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late Future<ConversationPage> _future = widget.repository
      .loadConversationPage();
  bool _loadingMore = false;
  int _pageRevision = 0;
  final Set<int> _openingConversationIds = {};

  Future<void> _reload() async {
    final revision = ++_pageRevision;
    if (_loadingMore) setState(() => _loadingMore = false);
    try {
      final page = await widget.repository.loadConversationPage();
      if (mounted && revision == _pageRevision) {
        setState(() {
          _future = Future.value(page);
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).refreshConversationsFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    }
  }

  void _retryInitialLoad() {
    setState(() {
      _pageRevision++;
      _loadingMore = false;
      _future = widget.repository.loadConversationPage();
    });
  }

  Future<void> _loadMore(ConversationPage current) async {
    if (_loadingMore || !current.hasMore) return;
    final revision = _pageRevision;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadConversationPage(
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      final knownIds = current.items.map((item) => item.id).toSet();
      final merged = ConversationPage(
        items: [
          ...current.items,
          ...next.items.where((item) => knownIds.add(item.id)),
        ],
        total: next.total,
        page: next.page,
        pageSize: next.pageSize,
      );
      if (mounted && revision == _pageRevision) {
        setState(() {
          _future = Future.value(merged);
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreConversationsFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted && revision == _pageRevision) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _openConversation(ConversationSummary conversation) async {
    if (_openingConversationIds.contains(conversation.id)) return;
    setState(() => _openingConversationIds.add(conversation.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            repository: widget.repository,
            conversation: conversation,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
      if (mounted) await _reload();
    } finally {
      if (mounted) {
        setState(() => _openingConversationIds.remove(conversation.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).directMessages)),
    body: FutureBuilder<ConversationPage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).conversationsLoadFailed(
                    localizeMessageError(
                      AppLocalizations.of(context),
                      snapshot.error!,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('conversation-list-retry'),
                  onPressed: _retryInitialLoad,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).reload),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final page = snapshot.data!;
        if (page.items.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context).noDirectMessages),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: page.items.length + (page.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              if (index == page.items.length) {
                return Center(
                  child: FilledButton.tonalIcon(
                    onPressed: _loadingMore ? null : () => _loadMore(page),
                    icon: _loadingMore
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      _loadingMore
                          ? AppLocalizations.of(context).loading
                          : AppLocalizations.of(context).loadMore,
                    ),
                  ),
                );
              }
              final item = page.items[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minVerticalPadding: 14,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE4D6),
                    child: Text(
                      item.peerNickname.isEmpty
                          ? AppLocalizations.of(context).anonymousPeer
                          : item.peerNickname.substring(0, 1),
                    ),
                  ),
                  title: Text(
                    item.peerNickname,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    item.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: item.unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85D2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${item.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _openingConversationIds.contains(item.id)
                      ? null
                      : () => _openConversation(item),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.repository,
    required this.conversation,
    required this.currentUserId,
  });
  final MessageRepository repository;
  final ConversationSummary conversation;
  final int currentUserId;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<DirectMessage> _messages = const [];
  MessagePage? _page;
  Object? _loadError;
  bool _loading = false,
      _loadingMore = false,
      _sending = false,
      _actionSaving = false,
      _blocked = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final page = widget.conversation.id == 0
          ? const MessagePage(items: [], total: 0, page: 1, pageSize: 20)
          : await widget.repository.loadMessagePage(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _page = page;
        _messages = page.items.reversed.toList();
        _loading = false;
        _loadError = null;
      });
      if (widget.conversation.id != 0) await _markRead();
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error;
        });
      }
    }
  }

  Future<void> _markRead() async {
    try {
      await widget.repository.markRead(widget.conversation.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).messageMarkReadFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    final current = _page;
    if (current == null || _loadingMore || !current.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadMessagePage(
        widget.conversation.id,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      final currentIds = _messages.map((message) => message.id).toSet();
      final merged = <DirectMessage>[
        ...next.items.reversed.where((message) => currentIds.add(message.id)),
        ..._messages,
      ];
      if (mounted) {
        setState(() {
          _page = next;
          _messages = merged;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadEarlierMessagesFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _blocked) return;
    setState(() => _sending = true);
    try {
      final sent = await widget.repository.send(
        widget.conversation.peerUserId,
        text,
      );
      if (mounted) {
        setState(() {
          _messages = [..._messages, sent];
          _controller.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).sendFailed(
                localizeMessageError(AppLocalizations.of(context), e),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _action(String value) async {
    if (_actionSaving) return;
    setState(() => _actionSaving = true);
    try {
      if (value == 'report') {
        if (widget.conversation.id == 0) return;
        await widget.repository.reportConversation(
          widget.conversation.id,
          AppLocalizations.of(context).harassmentOrInappropriate,
        );
      } else {
        final result = _blocked
            ? await widget.repository.unblock(widget.conversation.peerUserId)
            : await widget.repository.block(widget.conversation.peerUserId);
        if (mounted) setState(() => _blocked = result.blocked);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value == 'report'
                  ? AppLocalizations.of(context).reportSubmitted
                  : (_blocked
                        ? AppLocalizations.of(context).blockedBothWays
                        : AppLocalizations.of(context).unblocked),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).actionFailed(
                localizeMessageError(AppLocalizations.of(context), e),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionSaving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.conversation.peerNickname),
      actions: [
        PopupMenuButton<String>(
          enabled: !_actionSaving,
          onSelected: _action,
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'report',
              child: Text(AppLocalizations.of(context).reportConversation),
            ),
            PopupMenuItem(
              value: 'block',
              child: Text(
                _blocked
                    ? AppLocalizations.of(context).unblockUser
                    : AppLocalizations.of(context).blockUser,
              ),
            ),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null && _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).chatHistoryLoadFailed(
                          localizeMessageError(
                            AppLocalizations.of(context),
                            _loadError!,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('chat-history-retry'),
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context).reload),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _messages.length + ((_page?.hasMore ?? false) ? 1 : 0),
                  itemBuilder: (_, index) {
                    if ((_page?.hasMore ?? false) && index == 0) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: _loadingMore ? null : _loadMore,
                          icon: _loadingMore
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.history),
                          label: Text(
                            _loadingMore
                                ? AppLocalizations.of(context).loading
                                : AppLocalizations.of(
                                    context,
                                  ).loadEarlierMessages,
                          ),
                        ),
                      );
                    }
                    final messageIndex = (_page?.hasMore ?? false)
                        ? index - 1
                        : index;
                    final message = _messages[messageIndex];
                    final mine = message.fromUserId == widget.currentUserId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFFE85D2A) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(mine ? 18 : 5),
                            bottomRight: Radius.circular(mine ? 5 : 18),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: mine
                                ? Colors.white
                                : const Color(0xFF292522),
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
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_blocked,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _blocked
                          ? AppLocalizations.of(context).blockedComposerHint
                          : AppLocalizations.of(context).messageHint,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  key: const Key('chat-send-button'),
                  onPressed: _sending || _blocked ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  tooltip: AppLocalizations.of(context).send,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
