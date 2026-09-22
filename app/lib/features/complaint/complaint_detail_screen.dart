import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/complaint/complaint_repository.dart';
import 'package:flutter/material.dart';

/// 投诉详情：内容、商家申辩、仲裁结论与处理日志。
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.repository,
    required this.complaintId,
    this.initial,
  });

  final ComplaintRepository repository;
  final int complaintId;
  final ComplaintTicket? initial;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Future<ComplaintTicket> _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.repository.loadComplaint(widget.complaintId);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.complaintDetailTitle)),
      body: FutureBuilder<ComplaintTicket>(
        future: _ticket,
        initialData: widget.initial,
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(strings.complaintsLoadFailed(snapshot.error!)),
            );
          }
          final t = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(t.ticketNo, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(t.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${t.typeText} · ${t.shopName} · ${t.statusText}'),
              const Divider(height: 24),
              Text(t.content),
              const SizedBox(height: 16),
              Text(strings.complaintMerchantReply, style: Theme.of(context).textTheme.titleMedium),
              Text(t.merchantReply.isEmpty ? strings.complaintNoReply : t.merchantReply),
              if (t.resolution.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(strings.complaintResolution, style: Theme.of(context).textTheme.titleMedium),
                Text(t.resolution),
              ],
              if (t.logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(strings.complaintLogs, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...t.logs.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${log.createdAt ?? ''} · ${log.actorTypeText} · ${log.actionText}'
                        '${log.remark.isEmpty ? '' : ' — ${log.remark}'}',
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
