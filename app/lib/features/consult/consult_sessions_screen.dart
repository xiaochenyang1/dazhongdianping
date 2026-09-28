import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/consult/consult_chat_screen.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:flutter/material.dart';

/// 我的咨询会话列表。
class ConsultSessionsScreen extends StatefulWidget {
  const ConsultSessionsScreen({super.key, required this.repository});

  final ConsultRepository repository;

  @override
  State<ConsultSessionsScreen> createState() => _ConsultSessionsScreenState();
}

class _ConsultSessionsScreenState extends State<ConsultSessionsScreen> {
  late Future<List<ConsultSession>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.repository.loadSessions();
  }

  Future<void> _reload() async {
    final future = widget.repository.loadSessions();
    setState(() => _sessions = future);
    await future.catchError((_) => <ConsultSession>[]);
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
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myConsultTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<ConsultSession>>(
          future: _sessions,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.consultLoadFailed(snapshot.error!),
                      key: const Key('consult-sessions-error')),
                ),
              ]);
            }
            final sessions = snapshot.data ?? const [];
            if (sessions.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.consultSessionsEmpty, key: const Key('consult-sessions-empty')),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = sessions[index];
                return Card(
                  key: Key('consult-session-${s.id}'),
                  child: ListTile(
                    title: Text(s.shopName),
                    subtitle: Text(s.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: s.unread > 0
                        ? Badge(label: Text('${s.unread}'))
                        : const Icon(Icons.chevron_right),
                    onTap: () => _open(s),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
