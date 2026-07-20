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

  Future<void> createReservation() async {
    if (selected == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择时段')));
      return;
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '预订 ${result.reservationNo} 已创建：${result.statusText}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('预订失败：$error')));
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('在线预订')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text('日期 $dateText')),
              DropdownButton<int>(
                value: peopleCount,
                items: [1, 2, 3, 4, 5, 6]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count 人'),
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
              if (snapshot.hasError) return Text('时段加载失败：${snapshot.error}');
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (snapshot.data ?? const [])
                    .map(
                      (slot) => ChoiceChip(
                        label: Text(
                          '${slot.startTime}-${slot.endTime} · 剩余 ${slot.remainingCount}',
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
            decoration: const InputDecoration(
              labelText: '联系人',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '联系电话',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: remarkController,
            decoration: const InputDecoration(
              labelText: '备注',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: createReservation, child: const Text('提交预订')),
        ],
      ),
    );
  }
}
