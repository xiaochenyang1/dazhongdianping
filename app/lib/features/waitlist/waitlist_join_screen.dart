import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/waitlist/waitlist_repository.dart';
import 'package:flutter/material.dart';

/// 取号：为某门店选择桌型与人数并取号。
class WaitlistJoinScreen extends StatefulWidget {
  const WaitlistJoinScreen({super.key, required this.repository, required this.shopId});

  final WaitlistRepository repository;
  final int shopId;

  @override
  State<WaitlistJoinScreen> createState() => _WaitlistJoinScreenState();
}

class _WaitlistJoinScreenState extends State<WaitlistJoinScreen> {
  int _tableType = 1;
  int _partySize = 2;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final strings = AppLocalizations.of(context);
    try {
      await widget.repository.join(widget.shopId, tableType: _tableType, partySize: _partySize);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.waitlistJoinSuccess)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.waitlistJoinFailed(error))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.waitlistJoinTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(strings.waitlistTableType),
          DropdownButton<int>(
            key: const Key('waitlist-table-type'),
            value: _tableType,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 1, child: Text(strings.waitlistTableSmall)),
              DropdownMenuItem(value: 2, child: Text(strings.waitlistTableMedium)),
              DropdownMenuItem(value: 3, child: Text(strings.waitlistTableLarge)),
            ],
            onChanged: (v) => setState(() => _tableType = v ?? 1),
          ),
          const SizedBox(height: 12),
          Text(strings.waitlistPartySize),
          Row(
            children: [
              IconButton(
                key: const Key('waitlist-party-minus'),
                onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_partySize', key: const Key('waitlist-party-size')),
              IconButton(
                key: const Key('waitlist-party-plus'),
                onPressed: _partySize < 50 ? () => setState(() => _partySize++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('waitlist-join-submit'),
            onPressed: _submitting ? null : _submit,
            child: Text(strings.waitlistJoin),
          ),
        ],
      ),
    );
  }
}
