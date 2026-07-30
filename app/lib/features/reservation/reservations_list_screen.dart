import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_error_localizer.dart';
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
  List<({int? status, String label})> _tabs(AppLocalizations strings) => [
    (status: null, label: strings.filterAll),
    (status: 0, label: strings.reservationPending),
    (status: 1, label: strings.reservationConfirmed),
    (status: 2, label: strings.reservationArrived),
    (status: 3, label: strings.reservationUserCanceled),
    (status: 4, label: strings.reservationMerchantRejected),
    (status: 5, label: strings.reservationNoShow),
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
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.loadMoreReservationsFailed(
                localizeReservationError(strings, error),
              ),
            ),
          ),
        );
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
    final strings = AppLocalizations.of(context);
    final tabs = _tabs(strings);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myReservations)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: tabs
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
                  final error = localizeReservationError(
                    strings,
                    snapshot.error!,
                  );
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.reservationsLoadFailed(error)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('reservations-retry'),
                          onPressed: _retrying ? null : _retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _retrying ? strings.processing : strings.retry,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final page = snapshot.data!;
                final items = page.items;
                if (items.isEmpty) {
                  return Center(child: Text(strings.noReservationsForFilter));
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
                          label: Text(
                            _loadingMore ? strings.loading : strings.loadMore,
                          ),
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
                          strings.reservationListMeta(
                            no: item.reservationNo,
                            time: item.reserveTime,
                            people: item.peopleCount,
                            status: strings.reservationStatusLabel(
                              status: item.status,
                              fallback: item.statusText,
                            ),
                          ),
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
