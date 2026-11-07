import 'dart:async';

import 'package:dazhongdianping_app/features/invoice/invoice_repository.dart';
import 'package:dazhongdianping_app/features/invoice/invoices_screen.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/trade_error_localizer.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:share_plus/share_plus.dart';

typedef GroupBuyShareLauncher =
    Future<void> Function(String text, String subject, Rect? origin);
typedef GroupBuyClipboardWriter = Future<void> Function(String text);

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.repository,
    required this.orderId,
    this.initialOrder,
    this.thirdPartyConfig = const ThirdPartyConfig(),
    this.groupBuyShareLauncher,
    this.groupBuyClipboardWriter,
  });

  final TradeRepository repository;
  final int orderId;
  final TradeOrder? initialOrder;
  final ThirdPartyConfig thirdPartyConfig;
  final GroupBuyShareLauncher? groupBuyShareLauncher;
  final GroupBuyClipboardWriter? groupBuyClipboardWriter;

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
  bool _sharingGroupBuy = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    if (_order == null) {
      _load();
    } else {
      _syncCountdownTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
      if (mounted) {
        setState(() => _order = order);
        _syncCountdownTimer();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = localizeTradeError(AppLocalizations.of(context), error),
        );
      }
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
      AppLocalizations.of(context),
      ThirdPartyFeature.payment,
    );
    if (reason.isNotEmpty) {
      _showMessage(reason);
      return;
    }
    setState(() => _acting = true);
    try {
      final intent = await widget.repository.createPayment(widget.orderId);
      if (intent.needsCardConfirmation) {
        try {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: intent.clientSecret,
              merchantDisplayName: 'Dazhongdianping',
            ),
          );
          await Stripe.instance.presentPaymentSheet();
        } on StripeException catch (e) {
          if (e.error.code == FailureCode.Canceled) return;
          rethrow;
        }
        // Stripe 已授权;订单状态由 webhook 落库,轮询直到确认或超时。
        await _pollOrderUntilPaid();
        return;
      }
      if (mounted) {
        _showMessage(
          AppLocalizations.of(context).paymentRequestCreated(intent.channel),
        );
      }
    } catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context);
        _showMessage(
          strings.paymentStartFailed(localizeTradeError(strings, error)),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  static const Duration _pollInterval = Duration(milliseconds: 1500);
  static const int _pollMaxTries = 12;

  Future<void> _pollOrderUntilPaid() async {
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    _showMessage(strings.paymentConfirming);
    for (var attempt = 0; attempt < _pollMaxTries; attempt += 1) {
      try {
        final order = await widget.repository.loadOrder(widget.orderId);
        if (!mounted) return;
        setState(() => _order = order);
        if (order.payStatus != 0 || order.refund != null) {
          // 订单已确认:清掉"确认中"提示,订单卡片本身已切到已支付态。
          ScaffoldMessenger.of(context).clearSnackBars();
          return;
        }
      } catch (_) {
        // 瞬时网络错误:保持"正在确认"提示,下一轮继续重试。
      }
      await Future<void>.delayed(_pollInterval);
      if (!mounted) return;
    }
    if (!mounted) return;
    _showMessage(AppLocalizations.of(context).paymentReceived);
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
      _syncCountdownTimer();
      _showMessage(successMessage);
      return true;
    } catch (error) {
      if (mounted) {
        final strings = AppLocalizations.of(context);
        _showMessage(strings.actionFailed(localizeTradeError(strings, error)));
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

  void _syncCountdownTimer() {
    _countdownTimer?.cancel();
    final remaining = _groupBuyRemaining(_order);
    if (remaining == null || remaining == Duration.zero) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _groupBuyRemaining(_order);
      if (next == null || next == Duration.zero) timer.cancel();
      if (mounted) setState(() {});
    });
  }

  Duration? _groupBuyRemaining(TradeOrder? order) {
    if (order == null ||
        order.orderSource != 'groupbuy' ||
        order.groupBuyStatus != 1 ||
        order.expireAt.isEmpty) {
      return null;
    }
    final deadline = DateTime.tryParse(order.expireAt);
    if (deadline == null) return null;
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatCountdown(Duration remaining) {
    final seconds = remaining.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${rest.toString().padLeft(2, '0')}';
  }

  Future<void> _shareGroupBuy(TradeOrder order) async {
    final teamId = order.groupBuyTeamId;
    if (_sharingGroupBuy || teamId == null) return;
    setState(() => _sharingGroupBuy = true);
    final strings = AppLocalizations.of(context);
    final url = widget.thirdPartyConfig.groupBuyShareUrl(teamId);
    final title = order.campaignTitle.isEmpty
        ? order.dealTitle
        : order.campaignTitle;
    final text = strings.groupBuyShareText(
      title: title,
      paid: order.groupBuyPaidCount ?? 0,
      size: order.groupBuySize ?? 0,
      url: url,
    );
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final launcher = widget.groupBuyShareLauncher;
      if (launcher == null) {
        await Share.share(text, subject: title, sharePositionOrigin: origin);
      } else {
        await launcher(text, title, origin);
      }
      if (mounted) _showMessage(strings.shareCopied);
    } catch (_) {
      final clipboardWriter = widget.groupBuyClipboardWriter;
      if (clipboardWriter == null) {
        await Clipboard.setData(ClipboardData(text: text));
      } else {
        await clipboardWriter(text);
      }
      if (mounted) _showMessage(strings.shareCopied);
    } finally {
      if (mounted) setState(() => _sharingGroupBuy = false);
    }
  }

  String _groupBuyStatus(AppLocalizations strings, TradeOrder order) {
    final progress = strings.groupBuyProgress(
      paid: order.groupBuyPaidCount ?? 0,
      size: order.groupBuySize ?? 0,
    );
    if (order.groupBuyStatus == 2) {
      return '${strings.groupBuyFormed} · $progress';
    }
    if (order.groupBuyStatus == 3) {
      if (order.payStatus == 2) return strings.groupBuyRefunded;
      if (order.refund != null) return strings.groupBuyRefunding;
      return strings.groupBuyFailed;
    }
    return '${strings.groupBuyWaiting} · $progress';
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
    final groupBuyRemaining = _groupBuyRemaining(order);
    final activeGroupBuy =
        order.orderSource == 'groupbuy' && order.groupBuyStatus == 1;
    final paymentReason = widget.thirdPartyConfig.unavailableReason(
      strings,
      ThirdPartyFeature.payment,
    );
    final payStatusText = strings.payStatusLabel(
      status: order.payStatus,
      fallback: order.payStatusText,
    );
    final refundStatusText = order.refund == null
        ? null
        : strings.refundStatusLabel(
            status: order.refund!.status,
            fallback: order.refund!.statusText,
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
                  order.status == 2 && order.payStatus == 0
                      ? strings.orderClosed
                      : payStatusText,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (order.orderSource == 'seckill')
                  Text(
                    '${strings.flashSaleOrder} · ${order.campaignTitle}',
                    key: const Key('order-source'),
                  ),
                if (order.orderSource == 'groupbuy')
                  Text(
                    '${strings.groupBuyOrder} · ${_groupBuyStatus(strings, order)}',
                    key: const Key('groupbuy-status'),
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
        if (activeGroupBuy) ...[
          const SizedBox(height: 14),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (groupBuyRemaining != null)
                    Text(
                      strings.groupBuyCountdown(
                        _formatCountdown(groupBuyRemaining),
                      ),
                      key: const Key('groupbuy-countdown'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (order.groupBuyTeamId != null) ...[
                    if (groupBuyRemaining != null) const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      key: const Key('groupbuy-share-button'),
                      onPressed:
                          _sharingGroupBuy || groupBuyRemaining == Duration.zero
                          ? null
                          : () => _shareGroupBuy(order),
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(
                        _sharingGroupBuy
                            ? strings.sharing
                            : strings.groupBuyInvite,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
                  value: formatMoney(
                    order.unitPrice,
                    order.currency,
                    locale: strings.tag,
                  ),
                ),
                _DetailRow(
                  label: strings.paidAmount,
                  value: formatMoney(
                    order.amount,
                    order.currency,
                    locale: strings.tag,
                  ),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ),
        if (order.payStatus == 1)
          OutlinedButton.icon(
            key: const Key('order-invoice-button'),
            onPressed: _acting
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => InvoicesScreen(
                        repository: InvoiceRepository(widget.repository.api),
                        orderId: order.id,
                      ),
                    ),
                  ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(strings.invoiceRequest),
          ),
        if (order.payStatus == 0 && order.status == 1) ...[
          if (order.expireAt.isNotEmpty)
            Text(
              '${strings.orderPayDeadline} ${formatDisplayDateTime(order.expireAt, locale: strings.tag)}',
              key: const Key('order-deadline'),
            ),
          if (order.canPay == false) Text(strings.orderPaymentExpired),
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
            onPressed: _acting || order.canPay == false ? null : _pay,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.refundLabel(refundStatusText!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.refund!.refundType == 'late_payment'
                        ? strings.orderAutomaticRefund
                        : order.refund!.refundType == 'groupbuy_expired'
                        ? strings.groupBuyAutomaticRefund
                        : order.refund!.reason,
                  ),
                  if (order.refund!.channelFailureReason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(order.refund!.channelFailureReason),
                  ],
                  if (order.refund!.channelRefundTxn.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      strings.refundChannelReceipt(
                        order.refund!.channel,
                        order.refund!.channelRefundTxn,
                      ),
                    ),
                  ],
                ],
              ),
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
                subtitle: Text(
                  '${strings.couponStatusLabel(status: coupon.status, fallback: coupon.statusText)} · ${formatDisplayDate(coupon.expireAt, locale: strings.tag)}',
                ),
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
                  Text(
                    strings.couponDetailLoadFailed(
                      localizeTradeError(strings, snapshot.error!),
                    ),
                  ),
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
          final qrImageBytes = detail?.qrImageBytes;
          final couponStatusText = strings.couponStatusLabel(
            status: coupon.status,
            fallback: coupon.statusText,
          );
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
                            ? couponStatusText
                            : strings.statusWithRedeemability(
                                couponStatusText,
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
                      if (qrImageBytes != null) ...[
                        const SizedBox(height: 16),
                        Image.memory(
                          qrImageBytes,
                          key: const Key('coupon-qr-image'),
                          width: 220,
                          height: 220,
                          errorBuilder: (_, _, _) => Text(strings.qrLoadFailed),
                        ),
                      ] else if (detail != null) ...[
                        const SizedBox(height: 16),
                        Text(strings.qrLoadFailed),
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
                              : formatDisplayDate(
                                  coupon.expireAt,
                                  locale: strings.tag,
                                ),
                        ),
                      ),
                      if (detail != null &&
                          (detail.validStart.isNotEmpty ||
                              detail.validEnd.isNotEmpty))
                        Text(
                          strings.dealValidityRange(
                            start: detail.validStart.isEmpty
                                ? '—'
                                : formatDisplayDate(
                                    detail.validStart,
                                    locale: strings.tag,
                                  ),
                            end: detail.validEnd.isEmpty
                                ? '—'
                                : formatDisplayDate(
                                    detail.validEnd,
                                    locale: strings.tag,
                                  ),
                          ),
                        ),
                      if (detail != null && detail.verifyAt.isNotEmpty)
                        Text(
                          strings.verifiedAt(
                            formatDisplayDateTime(
                              detail.verifyAt,
                              locale: strings.tag,
                            ),
                          ),
                        ),
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
                        strings.detailRefreshFailed(
                          localizeTradeError(strings, snapshot.error!),
                        ),
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
