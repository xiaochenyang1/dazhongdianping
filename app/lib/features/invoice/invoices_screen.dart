import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/invoice/invoice_repository.dart';
import 'package:dazhongdianping_app/features/invoice/invoice_document_saver.dart';
import 'package:flutter/material.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({
    super.key,
    required this.repository,
    this.orderId,
    this.documentSaver,
  });
  final InvoiceRepository repository;
  final int? orderId;
  final InvoiceDocumentSaver? documentSaver;
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _titleForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _taxNo = TextEditingController();
  final _email = TextEditingController();
  List<InvoiceTitle> _titles = [];
  List<InvoiceOrder> _orders = [];
  List<InvoiceRequestItem> _invoices = [];
  int? _orderId;
  int? _filterOrderId;
  int? _titleId;
  int _titleType = 1;
  int _ordersPage = 1;
  int _invoicesPage = 1;
  bool _moreOrders = false;
  bool _moreInvoices = false;
  bool _loading = false;
  bool _writing = false;
  bool _ready = false;
  bool _showTitleForm = false;
  Object? _loadError;
  Object? _actionError;
  String? _success;
  bool get _busy => _loading || _writing;

  @override
  void initState() {
    super.initState();
    _filterOrderId = widget.orderId;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _taxNo.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load({bool afterWrite = false}) async {
    if (_loading || (_writing && !afterWrite)) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.titles(),
        widget.repository.orders(orderId: _filterOrderId),
        widget.repository.invoices(),
      ]);
      if (!mounted) return;
      final titles = results[0] as List<InvoiceTitle>;
      final orders = results[1] as InvoicePage<InvoiceOrder>;
      final invoices = results[2] as InvoicePage<InvoiceRequestItem>;
      setState(() {
        _titles = titles;
        _orders = orders.items;
        _invoices = invoices.items;
        _ordersPage = orders.page;
        _invoicesPage = invoices.page;
        _moreOrders = orders.hasMore;
        _moreInvoices = invoices.hasMore;
        if (!_orders.any((o) => o.id == _orderId)) {
          _orderId = _orders.any((o) => o.id == _filterOrderId)
              ? _filterOrderId
              : null;
        }
        if (!_titles.any((t) => t.id == _titleId)) {
          final defaults = _titles.where((t) => t.isDefault);
          _titleId = defaults.isNotEmpty
              ? defaults.first.id
              : _titles.firstOrNull?.id;
        }
        _ready = true;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore(bool orders) async {
    if (_busy) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (orders) {
        final next = await widget.repository.orders(
          page: _ordersPage + 1,
          orderId: _filterOrderId,
        );
        if (!mounted) return;
        setState(() {
          final ids = _orders.map((o) => o.id).toSet();
          _orders = [
            ..._orders,
            ...next.items.where((o) => !ids.contains(o.id)),
          ];
          _ordersPage = next.page;
          _moreOrders = next.hasMore;
        });
      } else {
        final next = await widget.repository.invoices(page: _invoicesPage + 1);
        if (!mounted) return;
        setState(() {
          final ids = _invoices.map((i) => i.id).toSet();
          _invoices = [
            ..._invoices,
            ...next.items.where((i) => !ids.contains(i.id)),
          ];
          _invoicesPage = next.page;
          _moreInvoices = next.hasMore;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTitle() async {
    if (_busy || !_titleForm.currentState!.validate()) return;
    setState(() {
      _writing = true;
      _actionError = null;
      _success = null;
    });
    try {
      final title = await widget.repository.saveTitle(
        titleType: _titleType,
        name: _name.text.trim(),
        taxNo: _titleType == 2 ? _taxNo.text.trim() : '',
        email: _email.text.trim(),
        isDefault: _titles.isEmpty,
      );
      if (!mounted) return;
      setState(() {
        _titles = [..._titles.where((t) => t.id != title.id), title];
        _titleId = title.id;
        _showTitleForm = false;
        _name.clear();
        _taxNo.clear();
        _email.clear();
        _success = AppLocalizations.of(context).invoiceTitleSaved;
      });
      _showFeedback(_success!);
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = error);
        _showFeedback(
          AppLocalizations.of(
            context,
          ).actionFailed(_error(AppLocalizations.of(context), error)),
        );
      }
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _request() async {
    if (_busy || !_ready || _orderId == null || _titleId == null) return;
    setState(() {
      _writing = true;
      _actionError = null;
      _success = null;
    });
    try {
      final created = await widget.repository.requestInvoice(
        orderId: _orderId!,
        titleId: _titleId!,
      );
      if (!mounted) return;
      setState(() {
        _invoices = [created, ..._invoices.where((i) => i.id != created.id)];
        _orders.removeWhere((o) => o.id == created.orderId);
        _orderId = null;
        // Removing an eligible order changes offsets; refresh before paging again.
        _moreOrders = false;
        _moreInvoices = false;
        _success = AppLocalizations.of(context).invoiceRequested;
      });
      _showFeedback(_success!);
      await _load(afterWrite: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error);
      _showFeedback(
        AppLocalizations.of(
          context,
        ).actionFailed(_error(AppLocalizations.of(context), error)),
      );
      if (error is ApiException &&
          (error.statusCode == 409 || error.statusCode == 404)) {
        await _load(afterWrite: true);
      }
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  Future<void> _documentAction(
    InvoiceRequestItem item, {
    required bool confirm,
  }) async {
    if (_busy || !item.documentAvailable) return;
    setState(() {
      _writing = true;
      _actionError = null;
      _success = null;
    });
    try {
      if (confirm) {
        final updated = await widget.repository.confirmReceipt(
          item.id,
          item.documentSha256,
        );
        if (!mounted) return;
        setState(() {
          _invoices = _invoices
              .map((i) => i.id == item.id ? updated : i)
              .toList();
          _success = AppLocalizations.of(context).invoiceReceived;
        });
      } else {
        final bytes = await widget.repository.download(item.id);
        if (!mounted) return;
        await (widget.documentSaver ?? InvoiceDocumentSaver()).save(
          item.id,
          bytes,
        );
        if (!mounted) return;
        setState(
          () => _success = AppLocalizations.of(context).invoiceDownloadReady,
        );
      }
      _showFeedback(_success!);
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error);
      _showFeedback(
        AppLocalizations.of(
          context,
        ).actionFailed(_error(AppLocalizations.of(context), error)),
      );
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _error(AppLocalizations s, Object error) => localizeAuthError(
    s,
    error,
    overrides: {
      '该订单已申请开票': s.invoiceAlreadyRequested,
      '订单不存在': s.invoiceOrderUnavailable,
      '订单未支付': s.invoiceOrderUnavailable,
      '订单参数无效': s.invoiceOrderUnavailable,
      '发票抬头不存在': s.invoiceChooseTitle,
      '企业抬头需填写税号': s.invoiceTaxRequired,
      '当前区域未配置税率': s.invoiceTaxUnavailable,
      '发票文件尚未交付': s.invoiceAwaitingPdf,
      '发票文件已变化，请刷新后确认': s.invoiceDocumentChanged,
      '开票申请不存在': s.invoiceOrderUnavailable,
      '账户已停用，无法交付发票': s.invoiceOrderUnavailable,
    },
  );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.invoicesTitle),
        actions: [
          IconButton(
            key: const Key('invoice-refresh'),
            tooltip: s.refresh,
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_loadError != null) ...[
            Text(
              s.actionFailed(_error(s, _loadError!)),
              key: const Key('invoice-load-error'),
            ),
            TextButton(
              key: const Key('invoice-retry'),
              onPressed: _busy ? null : _load,
              child: Text(s.retry),
            ),
          ],
          if (_success != null)
            Text(_success!, key: const Key('invoice-success')),
          if (_actionError != null)
            Text(
              s.actionFailed(_error(s, _actionError!)),
              key: const Key('invoice-action-error'),
            ),
          if (_ready) ...[
            Text(
              s.invoiceOrders,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_orders.isEmpty) Text(s.invoiceNoOrders),
            if (_orders.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey('invoice-order-${_orderId ?? 0}'),
                initialValue: _orderId,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.invoiceChooseOrder),
                items: _orders
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.id,
                        child: Text(
                          '${o.dealTitle} · ${o.shopName} · ${o.orderNo} · ${formatMoney(o.amount, o.currency, locale: s.tag)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy ? null : (id) => setState(() => _orderId = id),
              ),
            if (_moreOrders)
              TextButton(
                key: const Key('invoice-orders-more'),
                onPressed: _busy ? null : () => _loadMore(true),
                child: Text(s.loadMore),
              ),
            if (_filterOrderId != null)
              TextButton(
                key: const Key('invoice-other-orders'),
                onPressed: _busy
                    ? null
                    : () {
                        _filterOrderId = null;
                        _load();
                      },
                child: Text(s.invoiceOtherOrders),
              ),
            const SizedBox(height: 12),
            if (_titles.isNotEmpty)
              DropdownButtonFormField<int>(
                key: ValueKey('invoice-title-${_titleId ?? 0}'),
                initialValue: _titleId,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.invoiceChooseTitle),
                items: _titles
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          '${t.name}${t.taxNo.isEmpty ? '' : ' · ${t.taxNo}'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy ? null : (id) => setState(() => _titleId = id),
              ),
            TextButton(
              key: const Key('invoice-new-title'),
              onPressed: _busy
                  ? null
                  : () => setState(() => _showTitleForm = !_showTitleForm),
              child: Text(s.invoiceNewTitle),
            ),
            if (_showTitleForm)
              Form(
                key: _titleForm,
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      key: const Key('invoice-title-type'),
                      initialValue: _titleType,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(s.invoicePersonal),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(s.invoiceCompany),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (type) => setState(() => _titleType = type ?? 1),
                    ),
                    TextFormField(
                      key: const Key('invoice-name'),
                      controller: _name,
                      enabled: !_busy,
                      maxLength: 128,
                      decoration: InputDecoration(labelText: s.invoiceName),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? s.invoiceNameRequired
                          : null,
                    ),
                    if (_titleType == 2)
                      TextFormField(
                        key: const Key('invoice-tax-no'),
                        controller: _taxNo,
                        enabled: !_busy,
                        maxLength: 64,
                        decoration: InputDecoration(labelText: s.invoiceTaxNo),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? s.invoiceTaxRequired
                            : null,
                      ),
                    TextFormField(
                      key: const Key('invoice-email'),
                      controller: _email,
                      enabled: !_busy,
                      maxLength: 128,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: s.invoiceEmail),
                      validator: (value) =>
                          value != null &&
                              value.trim().isNotEmpty &&
                              !RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(value.trim())
                          ? s.invoiceEmailInvalid
                          : null,
                    ),
                    FilledButton(
                      key: const Key('invoice-save-title'),
                      onPressed: _busy ? null : _saveTitle,
                      child: Text(_writing ? s.submitting : s.invoiceSaveTitle),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('invoice-request'),
              onPressed: _busy || _orderId == null || _titleId == null
                  ? null
                  : _request,
              child: Text(_writing ? s.submitting : s.invoiceRequest),
            ),
            const SizedBox(height: 24),
            Text(
              s.invoiceHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_invoices.isEmpty) Text(s.invoiceHistoryEmpty),
            for (final item in _invoices)
              Card(
                key: Key('invoice-${item.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(switch (item.status) {
                        1 => s.invoicePending,
                        2 => s.invoiceIssued,
                        3 => s.invoiceRejected,
                        _ => s.invoiceUnavailable,
                      }),
                      Text(
                        formatMoney(item.amount, item.currency, locale: s.tag),
                      ),
                      Text(
                        '${s.invoiceTaxAmount}: ${formatMoney(item.taxAmount, item.currency, locale: s.tag)}',
                      ),
                      if (item.invoiceNo.isNotEmpty)
                        SelectableText('${s.invoiceNumber}: ${item.invoiceNo}'),
                      if (item.rejectReason.isNotEmpty) Text(item.rejectReason),
                      if (item.documentAvailable) ...[
                        TextButton.icon(
                          key: Key('invoice-download-${item.id}'),
                          onPressed: _busy
                              ? null
                              : () => _documentAction(item, confirm: false),
                          icon: const Icon(Icons.download),
                          label: Text(s.invoiceDownload),
                        ),
                        if (item.receivedAt.isNotEmpty)
                          Text(s.invoiceReceived)
                        else ...[
                          Text(s.invoiceReceiptHelp),
                          OutlinedButton(
                            key: Key('invoice-receipt-${item.id}'),
                            onPressed: _busy
                                ? null
                                : () => _documentAction(item, confirm: true),
                            child: Text(s.invoiceConfirmReceipt),
                          ),
                        ],
                      ] else if (item.status == 2)
                        Text(s.invoiceAwaitingPdf),
                    ],
                  ),
                ),
              ),
            if (_moreInvoices)
              TextButton(
                key: const Key('invoice-history-more'),
                onPressed: _busy ? null : () => _loadMore(false),
                child: Text(s.loadMore),
              ),
          ],
        ],
      ),
    );
  }
}
