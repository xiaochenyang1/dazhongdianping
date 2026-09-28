import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/waitlist/waitlist_repository.dart';
import 'package:flutter/material.dart';

/// 我的排队：查看进行中排队与进度，可取消。
class MyWaitlistScreen extends StatefulWidget {
  const MyWaitlistScreen({super.key, required this.repository});

  final WaitlistRepository repository;

  @override
  State<MyWaitlistScreen> createState() => _MyWaitlistScreenState();
}

class _MyWaitlistScreenState extends State<MyWaitlistScreen> {
  late Future<List<WaitlistEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.repository.loadMine();
  }

  Future<void> _reload() async {
    final future = widget.repository.loadMine();
    setState(() => _entries = future);
    await future.catchError((_) => <WaitlistEntry>[]);
  }

  Future<void> _cancel(WaitlistEntry entry) async {
    final strings = AppLocalizations.of(context);
    try {
      await widget.repository.cancel(entry.id);
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.waitlistCancelFailed(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myWaitlistTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<WaitlistEntry>>(
          future: _entries,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.waitlistLoadFailed(snapshot.error!), key: const Key('waitlist-error')),
                ),
              ]);
            }
            final entries = snapshot.data ?? const [];
            if (entries.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.waitlistEmpty, key: const Key('waitlist-empty')),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final e = entries[index];
                final subtitle = '${e.tableTypeText} · ${strings.waitlistNo} ${e.queueNo} · ${e.statusText}'
                    '${e.status == 1 ? ' · ${strings.waitlistAhead(e.aheadCount)}' : ''}';
                return Card(
                  key: Key('waitlist-${e.id}'),
                  child: ListTile(
                    title: Text(e.shopName),
                    subtitle: Text(subtitle),
                    trailing: e.status == 1
                        ? TextButton(
                            key: Key('waitlist-cancel-${e.id}'),
                            onPressed: () => _cancel(e),
                            child: Text(strings.waitlistCancel),
                          )
                        : null,
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
