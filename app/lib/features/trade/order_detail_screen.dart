import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.repository,
    required this.orderId,
    this.initialOrder,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final TradeRepository repository;
  final int orderId;
  final TradeOrder? initialOrder;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _refundReasonController = TextEditingController();
  TradeOrder? _order;
  String? _error;
  bool _loading = false;
  bool _acting = false;
  bool _confirmingCancel = false;
  bool _refundDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    if (_order == null) _load();
  }

  @override
  void dispose() {
    _refundReasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await widget.repository.loadOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    if (_acting || _confirmingCancel) return;
    setState(() => _confirmingCancel = true);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final strings = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(strings.cancelOrder),
            content: Text(strings.cancelOrderConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.keepOrder),
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
      () => widget.repository.cancelOrder(widget.orderId),
      AppLocalizations.of(context).orderCanceled,
    );
  }

  Future<void> _refund() async {
    if (_acting || _refundDialogOpen) return;
    setState(() => _refundDialogOpen = true);
    String? reason;
    try {
      reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final strings = AppLocalizations.of(context);
          if (_refundReasonController.text.trim().isEmpty) {
            _refundReasonController.text = strings.defaultRefundReason;
          }
          return AlertDialog(
            title: Text(strings.applyRefund),
            content: TextField(
              key: const Key('order-refund-reason'),
              controller: _refundReasonController,
              autofocus: true,
              decoration: InputDecoration(labelText: strings.refundReason),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(_refundReasonController.text.trim()),
                child: Text(strings.submitApplication),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _refundDialogOpen = false);
    }
    final refundReason = reason;
    if (refundReason == null || refundReason.isEmpty || !mounted) return;
    final succeeded = await _runAction(
      () => widget.repository.refundOrder(widget.orderId, reason: refundReason),
      AppLocalizations.of(context).refundSubmitted,
    );
    if (succeeded && mounted) {
      _refundReasonController.text = AppLocalizations.of(
        context,
      ).defaultRefundReason;
    }
  }

  Future<void> _pay() async {
    if (_acting) return;
    final reason = widget.thirdPartyConfig.unavailableReason(
      ThirdPartyFeature.payment,
    );
    if (reason.isNotEmpty) {
      _showMessage(reason);
      return;
    }
    setState(() => _acting = true);
    try {
      final intent = await widget.repository.createPayment(widget.orderId);
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context).paymentRequestCreated(intent.channel),
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).paymentStartFailed(error));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<bool> _runAction(
    Future<TradeOrder> Function() action,
    String successMessage,
  ) async {
    if (_acting) return false;
    setState(() => _acting = true);
    try {
      final order = await action();
      if (!mounted) return false;
      setState(() => _order = order);
      _showMessage(successMessage);
      return true;
    } catch (error) {
      if (mounted)
        _showMessage(AppLocalizations.of(context).actionFailed(error));
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
      appBar: AppBar(title: Text(strings.orderDetail)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton(
                key: const Key('order-detail-retry'),
                onPressed: _load,
                child: Text(strings.orderLoadFailedTapRetry),
              ),
            )
          : _buildOrder(context, _order!),
    );
  }

  Widget _buildOrder(BuildContext context, TradeOrder order) {
    final strings = AppLocalizations.of(context);
    final paymentReason = widget.thirdPartyConfig.unavailableReason(
      ThirdPartyFeature.payment,
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
                  order.payStatusText,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  order.dealTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  strings.orderShopMeta(
                    shop: order.shopName,
                    orderNo: order.orderNo,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _DetailRow(
                  label: strings.quantitySimple,
                  value: '${order.quantity}',
                ),
                _DetailRow(
                  label: strings.unitPrice,
                  value: formatMoney(order.unitPrice, order.currency),
                ),
                _DetailRow(
                  label: strings.paidAmount,
                  value: formatMoney(order.amount, order.currency),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ),
        if (order.payStatus == 0 && order.status == 1) ...[
          const SizedBox(height: 14),
          if (paymentReason.isNotEmpty)
            Card(
              color: const Color(0xFFFFF4D6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(paymentReason),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const Key('order-pay-button'),
            onPressed: _acting ? null : _pay,
            icon: const Icon(Icons.payments_outlined),
            label: Text(strings.startPayment),
          ),
          OutlinedButton(
            key: const Key('order-cancel-button'),
            onPressed: _acting || _confirmingCancel ? null : _cancel,
            child: Text(strings.cancelOrder),
          ),
        ],
        if (order.payStatus == 1 &&
            order.status == 1 &&
            order.refund == null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('order-refund-button'),
            onPressed: _acting || _refundDialogOpen ? null : _refund,
            icon: const Icon(Icons.currency_exchange),
            label: Text(strings.applyRefund),
          ),
        ],
        if (order.refund != null) ...[
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              title: Text(strings.refundLabel(order.refund!.statusText)),
              subtitle: Text(order.refund!.reason),
            ),
          ),
        ],
        if (order.coupons.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            strings.relatedCoupons,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...order.coupons.map(
            (coupon) => Card(
              child: ListTile(
                title: Text(coupon.code),
                subtitle: Text('${coupon.statusText} · ${coupon.expireAt}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CouponDetailScreen(
                      repository: widget.repository,
                      code: coupon.code,
                      initialCoupon: coupon,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CouponDetailScreen extends StatefulWidget {
  const CouponDetailScreen({
    super.key,
    required this.repository,
    required this.code,
    this.initialCoupon,
  });

  final TradeRepository repository;
  final String code;
  final Coupon? initialCoupon;

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  late Future<CouponDetail> _detail;
  bool _copyingCode = false;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadCouponDetail(widget.code);
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = widget.repository.loadCouponDetail(widget.code);
    setState(() {
      _detail = future;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _copyCode(String code) async {
    if (_copyingCode) return;
    setState(() => _copyingCode = true);
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).couponCopied)),
      );
    } finally {
      if (mounted) setState(() => _copyingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.couponDetail)),
      body: FutureBuilder<CouponDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              widget.initialCoupon == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && widget.initialCoupon == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.couponDetailLoadFailed(snapshot.error!)),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('coupon-detail-retry'),
                    onPressed: _reloading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }
          final detail = snapshot.data;
          final coupon = detail ?? widget.initialCoupon!;
          final usable = detail?.usable;
          final verifyHint = detail?.verifyHint.isNotEmpty == true
              ? detail!.verifyHint
              : strings.defaultVerifyHint;
          final qrImageUrl = detail?.qrImageUrl ?? '';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        usable == null
                            ? coupon.statusText
                            : strings.statusWithRedeemability(
                                coupon.statusText,
                                usable,
                              ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        coupon.code,
                        key: const Key('coupon-detail-code'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('copy-coupon-code'),
                        onPressed: _copyingCode
                            ? null
                            : () => _copyCode(coupon.code),
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(
                          _copyingCode
                              ? strings.copying
                              : strings.copyCouponCode,
                        ),
                      ),
                      if (qrImageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Image.network(
                          qrImageUrl,
                          key: const Key('coupon-qr-image'),
                          width: 220,
                          height: 220,
                          errorBuilder: (_, _, _) => Text(strings.qrLoadFailed),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.dealTitle,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(coupon.shopName),
                      Text(
                        strings.validUntilDate(
                          coupon.expireAt.isEmpty
                              ? strings.noExpiry
                              : coupon.expireAt,
                        ),
                      ),
                      if (detail != null &&
                          (detail.validStart.isNotEmpty ||
                              detail.validEnd.isNotEmpty))
                        Text(
                          strings.dealValidityRange(
                            start: detail.validStart.isEmpty
                                ? '—'
                                : detail.validStart,
                            end: detail.validEnd.isEmpty
                                ? '—'
                                : detail.validEnd,
                          ),
                        ),
                      if (detail != null && detail.verifyAt.isNotEmpty)
                        Text(strings.verifiedAt(detail.verifyAt)),
                    ],
                  ),
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.usageRules,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.rules.isEmpty
                              ? strings.noExtraRules
                              : detail.rules,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(strings.showCodeToMerchant),
                  subtitle: Text(verifyHint),
                ),
              ),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.detailRefreshFailed(snapshot.error!),
                        style: const TextStyle(color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('coupon-detail-fallback-retry'),
                        onPressed: _reloading ? null : _reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          _reloading
                              ? strings.processing
                              : strings.reloadFullDetail,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
