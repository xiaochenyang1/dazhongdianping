import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/creator/creator_repository.dart';
import 'package:flutter/material.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key, required this.repository, this.orderId});

  final InvoiceRepository repository;
  final int? orderId;

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late Future<List<InvoiceRequestItem>> _invoices;
  final _name = TextEditingController();
  final _taxNo = TextEditingController();
  final _orderId = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) _orderId.text = '${widget.orderId}';
    _invoices = widget.repository.invoices();
  }

  @override
  void dispose() {
    _name.dispose();
    _taxNo.dispose();
    _orderId.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = widget.repository.invoices();
    setState(() => _invoices = future);
    await future;
  }

  Future<void> _request() async {
    final titles = await widget.repository.titles();
    var titleId = titles.isEmpty ? 0 : titles.first.id;
    if (titleId == 0 && _name.text.trim().isNotEmpty) {
      await widget.repository.saveTitle(titleType: 1, name: _name.text.trim(), taxNo: _taxNo.text.trim());
      final created = await widget.repository.titles();
      titleId = created.isEmpty ? 0 : created.last.id;
    }
    final orderId = int.tryParse(_orderId.text.trim()) ?? 0;
    if (orderId == 0 || titleId == 0) return;
    await widget.repository.requestInvoice(orderId: orderId, titleId: titleId);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.invoicesTitle)),
      body: FutureBuilder<List<InvoiceRequestItem>>(
        future: _invoices,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <InvoiceRequestItem>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(controller: _orderId, decoration: const InputDecoration(labelText: 'orderId')),
              TextField(controller: _name, decoration: InputDecoration(labelText: strings.invoiceName)),
              TextField(controller: _taxNo, decoration: InputDecoration(labelText: strings.invoiceTaxNo)),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(onPressed: _request, child: Text(strings.invoiceRequest)),
              ),
              if (snapshot.hasError) Text('${snapshot.error}'),
              for (final item in items)
                ListTile(
                  key: Key('invoice-${item.id}'),
                  title: Text('#${item.orderId} ${item.statusText}'),
                  subtitle: Text('${item.amount} / ${item.taxAmount}'),
                ),
            ],
          );
        },
      ),
    );
  }
}
