import 'package:dazhongdianping_app/features/reservation/reservation_detail_screen.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter/material.dart';

class ReservationsListScreen extends StatefulWidget {
  const ReservationsListScreen({
    super.key,
    required this.repository,
    this.initialStatus,
  });

  final ReservationRepository repository;
  final int? initialStatus;

  @override
  State<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  static const _tabs = <({int? status, String label})>[
    (status: null, label: '全部'),
    (status: 0, label: '待确认'),
    (status: 1, label: '已确认'),
    (status: 2, label: '已到店'),
    (status: 3, label: '用户取消'),
    (status: 4, label: '商户拒绝'),
    (status: 5, label: '爽约'),
  ];

  late int? _status;
  late Future<List<ReservationSummary>> _reservations;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _reservations = widget.repository.loadReservations(status: _status);
  }

  void _reload() {
    final future = widget.repository.loadReservations(status: _status);
    setState(() {
      _reservations = future;
    });
  }

  void _selectStatus(int? status) {
    if (_status == status) return;
    setState(() => _status = status);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的预订')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: _tabs
                  .map(
                    (tab) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('reservation-tab-${tab.status ?? 'all'}'),
                        label: Text(tab.label),
                        selected: _status == tab.status,
                        onSelected: (_) => _selectStatus(tab.status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReservationSummary>>(
              future: _reservations,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('预订加载失败：${snapshot.error}'));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('当前筛选下暂无预订'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      key: Key('reservation-card-${item.id}'),
                      child: ListTile(
                        title: Text(
                          item.shopName.isEmpty
                              ? item.reservationNo
                              : item.shopName,
                        ),
                        subtitle: Text(
                          '${item.reservationNo}\n${item.reserveTime} · ${item.peopleCount} 人 · ${item.statusText}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => ReservationDetailScreen(
                                  repository: widget.repository,
                                  reservationId: item.id,
                                ),
                              ),
                            )
                            .then((_) {
                              if (mounted) _reload();
                            }),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
