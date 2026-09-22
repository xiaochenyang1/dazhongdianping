import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/complaint/complaint_repository.dart';
import 'package:flutter/material.dart';

/// 发起投诉：针对某门店（可选关联订单）提交投诉。
class ComplaintCreateScreen extends StatefulWidget {
  const ComplaintCreateScreen({
    super.key,
    required this.repository,
    required this.shopId,
    this.orderId,
  });

  final ComplaintRepository repository;
  final int shopId;
  final int? orderId;

  @override
  State<ComplaintCreateScreen> createState() => _ComplaintCreateScreenState();
}

class _ComplaintCreateScreenState extends State<ComplaintCreateScreen> {
  int _type = 1;
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<int>> _typeItems(AppLocalizations strings) => [
        DropdownMenuItem(value: 1, child: Text(strings.complaintTypeQuality)),
        DropdownMenuItem(value: 2, child: Text(strings.complaintTypeFalseAd)),
        DropdownMenuItem(value: 3, child: Text(strings.complaintTypeRefund)),
        DropdownMenuItem(value: 4, child: Text(strings.complaintTypeService)),
        DropdownMenuItem(value: 5, child: Text(strings.complaintTypeOther)),
      ];

  Future<void> _submit() async {
    if (_submitting) return;
    final strings = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.repository.createComplaint(
        shopId: widget.shopId,
        orderId: widget.orderId,
        type: _type,
        title: _title.text.trim(),
        content: _content.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.complaintSubmitSuccess)),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.complaintSubmitFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.complaintCreateTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(strings.complaintTypeLabel),
          DropdownButton<int>(
            key: const Key('complaint-type'),
            value: _type,
            isExpanded: true,
            items: _typeItems(strings),
            onChanged: (v) => setState(() => _type = v ?? 1),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('complaint-title'),
            controller: _title,
            maxLength: 128,
            decoration: InputDecoration(
              labelText: strings.complaintTitleLabel,
              hintText: strings.complaintTitleHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('complaint-content'),
            controller: _content,
            maxLength: 2000,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: strings.complaintContentLabel,
              hintText: strings.complaintContentHint,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('complaint-submit'),
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? strings.complaintSubmitting : strings.complaintSubmit),
          ),
        ],
      ),
    );
  }
}
