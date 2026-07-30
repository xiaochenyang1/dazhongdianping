import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_error_localizer.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter/material.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({
    super.key,
    required this.repository,
    required this.shopId,
    this.initialDate,
  });
  final ReservationRepository repository;
  final int shopId;
  final DateTime? initialDate;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late DateTime date;
  int peopleCount = 2;
  ReservationSlot? selected;
  late Future<List<ReservationSlot>> slots;
  bool retryingSlots = false;
  bool creating = false;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    date = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    slots = loadSlots();
  }

  String get dateText =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Future<List<ReservationSlot>> loadSlots() => widget.repository.loadSlots(
    shopId: widget.shopId,
    date: dateText,
    peopleCount: peopleCount,
  );

  Future<void> retrySlots() async {
    if (retryingSlots) return;
    final future = loadSlots();
    setState(() {
      slots = future;
      selected = null;
      retryingSlots = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => retryingSlots = false);
    }
  }

  Future<void> createReservation() async {
    if (creating) return;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).selectSlotFirst)),
      );
      return;
    }
    setState(() => creating = true);
    try {
      final result = await widget.repository.create(
        shopId: widget.shopId,
        slotId: selected!.slotId,
        peopleCount: peopleCount,
        contactName: nameController.text.trim(),
        contactPhone: phoneController.text.trim(),
        remark: remarkController.text.trim(),
      );
      if (mounted) {
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.reservationCreated(
                no: result.reservationNo,
                status: strings.reservationStatusLabel(
                  status: result.status,
                  fallback: result.statusText,
                ),
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.reservationFailed(
                localizeReservationError(strings, error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.onlineReservation)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text(strings.dateLabel(dateText))),
              DropdownButton<int>(
                value: peopleCount,
                items: [1, 2, 3, 4, 5, 6]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text(strings.peopleCount(count)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    peopleCount = value;
                    selected = null;
                    slots = loadSlots();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ReservationSlot>>(
            future: slots,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final error = localizeReservationError(
                  strings,
                  snapshot.error!,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.slotsLoadFailed(error)),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      key: const Key('reservation-slots-retry'),
                      onPressed: retryingSlots ? null : retrySlots,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        retryingSlots ? strings.processing : strings.retry,
                      ),
                    ),
                  ],
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (snapshot.data ?? const [])
                    .map(
                      (slot) => ChoiceChip(
                        label: Text(
                          strings.slotRemaining(
                            start: slot.startTime,
                            end: slot.endTime,
                            count: slot.remainingCount,
                          ),
                        ),
                        selected: selected?.slotId == slot.slotId,
                        onSelected: slot.available
                            ? (_) => setState(() => selected = slot)
                            : null,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: strings.contactName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: strings.contactPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: remarkController,
            decoration: InputDecoration(
              labelText: strings.remark,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('reservation-submit'),
            onPressed: creating ? null : createReservation,
            child: Text(
              creating ? strings.submitting : strings.submitReservation,
            ),
          ),
        ],
      ),
    );
  }
}
