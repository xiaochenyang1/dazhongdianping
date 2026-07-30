import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_error_localizer.dart';
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
  bool _loading = false;
  bool _acting = false;
  bool _confirmingCancel = false;
  bool _pickingDate = false;
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
    if (_loading) return;
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
      if (mounted) {
        final strings = AppLocalizations.of(context);
        setState(() => _error = localizeReservationError(strings, error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    if (_acting || _confirmingCancel || _pickingDate) return;
    setState(() => _confirmingCancel = true);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final strings = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(strings.cancelReservation),
            content: Text(strings.cancelReservationConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.keepReservation),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.confirmCancel),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _confirmingCancel = false);
    }
    if (confirmed != true || !mounted) return;
    await _runAction(
      () => widget.repository.cancelReservation(widget.reservationId),
      AppLocalizations.of(context).reservationCanceled,
    );
  }

  Future<void> _pickDate() async {
    if (_acting || _confirmingCancel || _pickingDate) return;
    setState(() => _pickingDate = true);
    DateTime? next;
    try {
      next = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 180)),
      );
    } finally {
      if (mounted) setState(() => _pickingDate = false);
    }
    final selectedDate = next;
    if (selectedDate != null && mounted) {
      setState(() {
        _date = selectedDate;
        _slots = const [];
        _selectedSlot = null;
      });
    }
  }

  Future<void> _findSlots() async {
    if (_acting || _pickingDate) return;
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
      if (mounted) {
        final strings = AppLocalizations.of(context);
        _showMessage(
          strings.slotsLoadFailed(localizeReservationError(strings, error)),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reschedule() async {
    final slot = _selectedSlot;
    if (slot == null || _acting || _pickingDate) return;
    final succeeded = await _runAction(
      () => widget.repository.rescheduleReservation(
        widget.reservationId,
        slotId: slot.slotId,
        reserveTime: '$_dateText ${slot.startTime}',
        reason: AppLocalizations.of(context).rescheduleReason,
      ),
      AppLocalizations.of(context).reservationRescheduled,
    );
    if (succeeded && mounted) {
      setState(() {
        _slots = const [];
        _selectedSlot = null;
      });
    }
  }

  Future<bool> _runAction(
    Future<ReservationDetail> Function() action,
    String message,
  ) async {
    if (_acting) return false;
    setState(() => _acting = true);
    try {
      final reservation = await action();
      if (!mounted) return false;
      setState(() => _reservation = reservation);
      _showMessage(message);
      return true;
    } catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context);
        _showMessage(
          strings.actionFailed(localizeReservationError(strings, error)),
        );
      }
      return false;
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.reservationDetail)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton(
                key: const Key('reservation-detail-retry'),
                onPressed: _load,
                child: Text(strings.reservationLoadFailedTapRetry),
              ),
            )
          : _buildDetail(context, _reservation!),
    );
  }

  Widget _buildDetail(BuildContext context, ReservationDetail reservation) {
    final strings = AppLocalizations.of(context);
    final statusText = strings.reservationStatusLabel(
      status: reservation.status,
      fallback: reservation.statusText,
    );
    final confirmModeText = strings.reservationConfirmModeLabel(
      mode: reservation.confirmMode,
      fallback: reservation.confirmModeText,
    );
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
                  statusText,
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
                  strings.reservationTimePeople(
                    time: reservation.reserveTime,
                    people: reservation.peopleCount,
                  ),
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
              '$confirmModeText${reservation.remark.isEmpty ? '' : ' · ${reservation.remark}'}',
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
                  key: const Key('reservation-cancel-button'),
                  onPressed: _acting || _confirmingCancel || _pickingDate
                      ? null
                      : _cancel,
                  child: Text(strings.cancelReservation),
                ),
              if (reservation.canReschedule)
                OutlinedButton.icon(
                  key: const Key('reservation-pick-date'),
                  onPressed: _acting || _pickingDate ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_dateText),
                ),
              if (reservation.canReschedule)
                FilledButton.tonal(
                  key: const Key('reservation-find-slots'),
                  onPressed: _acting || _pickingDate ? null : _findSlots,
                  child: Text(strings.findRescheduleSlots),
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
                      strings.rescheduleSlotMeta(
                        start: slot.startTime,
                        mode: strings.reservationConfirmModeLabel(
                          mode: slot.confirmMode,
                          fallback: slot.confirmModeText,
                        ),
                        count: slot.remainingCount,
                      ),
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
            onPressed: _selectedSlot == null || _acting || _pickingDate
                ? null
                : _reschedule,
            child: Text(strings.confirmReschedule),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          strings.changeTimeline,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (reservation.timeline.isEmpty)
          Card(child: ListTile(title: Text(strings.noChangeRecords)))
        else
          ...reservation.timeline.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  strings.reservationTimelineActionLabel(
                    actionType: item.actionType,
                    fallback: item.actionText,
                  ),
                ),
                subtitle: Text('${item.remark}\n${item.createdAt}'),
              ),
            ),
          ),
      ],
    );
  }
}
