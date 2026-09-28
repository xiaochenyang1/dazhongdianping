import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/complaint/complaint_detail_screen.dart';
import 'package:dazhongdianping_app/features/complaint/complaint_repository.dart';
import 'package:flutter/material.dart';

/// 我的投诉列表。
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key, required this.repository});

  final ComplaintRepository repository;

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late Future<List<ComplaintTicket>> _tickets;

  @override
  void initState() {
    super.initState();
    _tickets = widget.repository.loadMyComplaints();
  }

  Future<void> _reload() async {
    final future = widget.repository.loadMyComplaints();
    setState(() => _tickets = future);
    await future.catchError((_) => <ComplaintTicket>[]);
  }

  Future<void> _open(ComplaintTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(
          repository: widget.repository,
          complaintId: ticket.id,
          initial: ticket,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myComplaintsTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<ComplaintTicket>>(
          future: _tickets,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.complaintsLoadFailed(snapshot.error!),
                      key: const Key('complaints-error')),
                ),
              ]);
            }
            final tickets = snapshot.data ?? const [];
            if (tickets.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.complaintsEmpty, key: const Key('complaints-empty')),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final t = tickets[index];
                return Card(
                  key: Key('complaint-${t.id}'),
                  child: ListTile(
                    title: Text(t.title),
                    subtitle: Text('${t.typeText} · ${t.shopName}\n${t.statusText}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(t),
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
