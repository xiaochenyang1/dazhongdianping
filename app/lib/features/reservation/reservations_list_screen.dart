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
  late Future<ReservationPage> _reservations;
  bool _loadingMore = false;
  bool _retrying = false;
  final Set<int> _openingReservationIds = <int>{};
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _reservations = widget.repository.loadReservationPage(status: _status);
  }

  void _reload() {
    _requestId++;
    final future = widget.repository.loadReservationPage(status: _status);
    setState(() {
      _reservations = future;
      _loadingMore = false;
    });
  }

  Future<void> _retry() async {
    if (_retrying) return;
    _requestId++;
    final future = widget.repository.loadReservationPage(status: _status);
    setState(() {
      _reservations = future;
      _loadingMore = false;
      _retrying = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _loadMore(ReservationPage current) async {
    if (_loadingMore || !current.hasMore) return;
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadReservationPage(
        status: _status,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      final knownIds = current.items.map((item) => item.id).toSet();
      final items = [
        ...current.items,
        ...next.items.where((item) => knownIds.add(item.id)),
      ];
      setState(() {
        _reservations = Future.value(
          ReservationPage(
            items: items,
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && requestId == _requestId) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多预订失败：$error')));
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _selectStatus(int? status) {
    if (_status == status) return;
    setState(() => _status = status);
    _reload();
  }

  Future<void> _openReservation(ReservationSummary reservation) async {
    if (_openingReservationIds.contains(reservation.id)) return;
    setState(() => _openingReservationIds.add(reservation.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReservationDetailScreen(
            repository: widget.repository,
            reservationId: reservation.id,
          ),
        ),
      );
      if (mounted) _reload();
    } finally {
      if (mounted) {
        setState(() => _openingReservationIds.remove(reservation.id));
      }
    }
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
            child: FutureBuilder<ReservationPage>(
              future: _reservations,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('预订加载失败：${snapshot.error}'),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('reservations-retry'),
                          onPressed: _retrying ? null : _retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(_retrying ? '处理中...' : '重试'),
                        ),
                      ],
                    ),
                  );
                }
                final page = snapshot.data!;
                final items = page.items;
                if (items.isEmpty) {
                  return const Center(child: Text('当前筛选下暂无预订'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Center(
                        child: OutlinedButton.icon(
                          key: const Key('reservations-load-more'),
                          onPressed: _loadingMore
                              ? null
                              : () => _loadMore(page),
                          icon: _loadingMore
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(_loadingMore ? '加载中...' : '加载更多'),
                        ),
                      );
                    }
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
                        onTap: _openingReservationIds.contains(item.id)
                            ? null
                            : () => _openReservation(item),
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
