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
  late Future<List<ConversationSummary>> _future = widget.repository
      .loadConversations();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('私信')),
    body: FutureBuilder<List<ConversationSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('会话加载失败：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('还没有私信，去公开主页打个招呼吧。'));
        }
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() => _future = widget.repository.loadConversations()),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = snapshot.data![index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minVerticalPadding: 14,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE4D6),
                    child: Text(
                      item.peerNickname.isEmpty
                          ? 'TA'
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
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          repository: widget.repository,
                          conversation: item,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                    if (mounted) {
                      setState(
                        () => _future = widget.repository.loadConversations(),
                      );
                    }
                  },
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
  bool _loading = true, _sending = false, _blocked = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = widget.conversation.id == 0
          ? <DirectMessage>[]
          : await widget.repository.loadMessages(widget.conversation.id);
      if (widget.conversation.id != 0) {
        await widget.repository.markRead(widget.conversation.id);
      }
      if (mounted) {
        setState(() {
          _messages = items.reversed.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _action(String value) async {
    try {
      if (value == 'report') {
        if (widget.conversation.id == 0) return;
        await widget.repository.reportConversation(
          widget.conversation.id,
          '骚扰或不当内容',
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
                  ? '举报已提交'
                  : (_blocked ? '已拉黑，双方无法继续发送' : '已解除拉黑'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
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
          onSelected: _action,
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'report', child: Text('举报会话')),
            PopupMenuItem(
              value: 'block',
              child: Text(_blocked ? '解除拉黑' : '拉黑用户'),
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) {
                    final message = _messages[index];
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
                      hintText: _blocked ? '已拉黑，解除后可继续发送' : '写点什么…',
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
                  onPressed: _sending || _blocked ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  tooltip: '发送',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
