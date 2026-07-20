import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter/material.dart';

class ReservationDetailScreen extends StatefulWidget {
  const ReservationDetailScreen({
    super.key,
    required this.repository,
    required this.reservationId,
    this.initialRescheduleDate,
  });
  final ReservationRepository repository;
  final int reservationId;
  final DateTime? initialRescheduleDate;

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  ReservationDetail? _reservation;
  List<ReservationSlot> _slots = const [];
  ReservationSlot? _selectedSlot;
  late DateTime _date;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date =
        widget.initialRescheduleDate ??
        DateTime.now().add(const Duration(days: 1));
    _load();
  }

  String get _dateText =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reservation = await widget.repository.loadReservation(
        widget.reservationId,
      );
      if (mounted) setState(() => _reservation = reservation);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消预订'),
        content: const Text('取消时间限制由门店规则决定，确定继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('先不取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runAction(
      () => widget.repository.cancelReservation(widget.reservationId),
      '预订已取消',
    );
  }

  Future<void> _pickDate() async {
    final next = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (next != null && mounted) {
      setState(() {
        _date = next;
        _slots = const [];
        _selectedSlot = null;
      });
    }
  }

  Future<void> _findSlots() async {
    final reservation = _reservation!;
    setState(() => _acting = true);
    try {
      final slots = await widget.repository.loadSlots(
        shopId: reservation.shopId,
        date: _dateText,
        peopleCount: reservation.peopleCount,
      );
      if (mounted) {
        setState(() {
          _slots = slots;
          _selectedSlot = null;
        });
      }
    } catch (error) {
      if (mounted) _showMessage('时段加载失败：$error');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reschedule() async {
    final slot = _selectedSlot;
    if (slot == null) return;
    await _runAction(
      () => widget.repository.rescheduleReservation(
        widget.reservationId,
        slotId: slot.slotId,
        reserveTime: '$_dateText ${slot.startTime}',
        reason: '用户在线改期',
      ),
      '预订已改期',
    );
    if (mounted) {
      setState(() {
        _slots = const [];
        _selectedSlot = null;
      });
    }
  }

  Future<void> _runAction(
    Future<ReservationDetail> Function() action,
    String message,
  ) async {
    setState(() => _acting = true);
    try {
      final reservation = await action();
      if (!mounted) return;
      setState(() => _reservation = reservation);
      _showMessage(message);
    } catch (error) {
      if (mounted) _showMessage('操作失败：$error');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('预订详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: const Text('预订加载失败，点击重试'),
              ),
            )
          : _buildDetail(context, _reservation!),
    );
  }

  Widget _buildDetail(BuildContext context, ReservationDetail reservation) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.statusText,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  reservation.shopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${reservation.reserveTime} · ${reservation.peopleCount} 人',
                ),
                Text(reservation.address),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text(
              '${reservation.contactName} · ${reservation.contactPhone}',
            ),
            subtitle: Text(
              '${reservation.confirmModeText}${reservation.remark.isEmpty ? '' : ' · ${reservation.remark}'}',
            ),
          ),
        ),
        if (reservation.canCancel || reservation.canReschedule) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (reservation.canCancel)
                OutlinedButton(
                  onPressed: _acting ? null : _cancel,
                  child: const Text('取消预订'),
                ),
              if (reservation.canReschedule)
                OutlinedButton.icon(
                  onPressed: _acting ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_dateText),
                ),
              if (reservation.canReschedule)
                FilledButton.tonal(
                  onPressed: _acting ? null : _findSlots,
                  child: const Text('查询改期时段'),
                ),
            ],
          ),
        ],
        if (_slots.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(
                      '${slot.startTime} · ${slot.confirmModeText} · 余 ${slot.remainingCount}',
                    ),
                    selected: _selectedSlot?.slotId == slot.slotId,
                    onSelected: slot.available
                        ? (_) => setState(() => _selectedSlot = slot)
                        : null,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _selectedSlot == null || _acting ? null : _reschedule,
            child: const Text('确认改期'),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          '变更时间线',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (reservation.timeline.isEmpty)
          const Card(child: ListTile(title: Text('暂无变更记录')))
        else
          ...reservation.timeline.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(item.actionText),
                subtitle: Text('${item.remark}\n${item.createdAt}'),
              ),
            ),
          ),
      ],
    );
  }
}
