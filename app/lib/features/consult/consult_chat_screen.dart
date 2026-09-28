import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:flutter/material.dart';

/// 咨询聊天界面。
class ConsultChatScreen extends StatefulWidget {
  const ConsultChatScreen({
    super.key,
    required this.repository,
    required this.sessionId,
    this.title = '',
  });

  final ConsultRepository repository;
  final int sessionId;
  final String title;

  @override
  State<ConsultChatScreen> createState() => _ConsultChatScreenState();
}

class _ConsultChatScreenState extends State<ConsultChatScreen> {
  late Future<ConsultThread> _thread;
  final _input = TextEditingController();
  List<ConsultMessage> _messages = const [];
  bool _sending = false;
  String _title = '';

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _thread = _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<ConsultThread> _load() async {
    final thread = await widget.repository.loadThread(widget.sessionId);
    _messages = thread.messages;
    if (thread.session.shopName.isNotEmpty) _title = thread.session.shopName;
    return thread;
  }

  Future<void> _send() async {
    if (_sending) return;
    final content = _input.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    final strings = AppLocalizations.of(context);
    try {
      final message = await widget.repository.sendMessage(widget.sessionId, content);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _input.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.consultSendFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title.isEmpty ? strings.myConsultTitle : _title)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<ConsultThread>(
              future: _thread,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(strings.consultLoadFailed(snapshot.error!),
                        key: const Key('consult-chat-error')),
                  );
                }
                if (_messages.isEmpty) {
                  return Center(child: Text(strings.consultMessagesEmpty));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final mine = m.senderType == 1;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        key: Key('consult-msg-${m.id}'),
                        color: mine ? Theme.of(context).colorScheme.primaryContainer : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mine ? strings.consultYou : strings.consultMerchant,
                                  style: Theme.of(context).textTheme.labelSmall),
                              Text(m.content),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                      decoration: InputDecoration(hintText: strings.consultInputHint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('consult-send'),
                    onPressed: _sending ? null : _send,
                    child: Text(strings.consultSend),
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
