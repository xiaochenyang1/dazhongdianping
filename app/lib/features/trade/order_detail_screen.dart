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
  final _refundReasonController = TextEditingController(text: '行程有变');
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
        builder: (context) => AlertDialog(
          title: const Text('取消订单'),
          content: const Text('订单取消后将释放库存，确定继续？'),
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
    } finally {
      if (mounted) setState(() => _confirmingCancel = false);
    }
    if (confirmed != true || !mounted) return;
    await _runAction(
      () => widget.repository.cancelOrder(widget.orderId),
      '订单已取消',
    );
  }

  Future<void> _refund() async {
    if (_acting || _refundDialogOpen) return;
    setState(() => _refundDialogOpen = true);
    String? reason;
    try {
      reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('申请退款'),
          content: TextField(
            key: const Key('order-refund-reason'),
            controller: _refundReasonController,
            autofocus: true,
            decoration: const InputDecoration(labelText: '退款原因'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(_refundReasonController.text.trim()),
              child: const Text('提交申请'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _refundDialogOpen = false);
    }
    final refundReason = reason;
    if (refundReason == null || refundReason.isEmpty || !mounted) return;
    final succeeded = await _runAction(
      () => widget.repository.refundOrder(widget.orderId, reason: refundReason),
      '退款申请已提交',
    );
    if (succeeded) _refundReasonController.text = '行程有变';
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
      if (mounted) _showMessage('已创建 ${intent.channel} 支付请求，请在支付渠道完成付款');
    } catch (error) {
      if (mounted) _showMessage('支付发起失败：$error');
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
      if (mounted) _showMessage('操作失败：$error');
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
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton(
                key: const Key('order-detail-retry'),
                onPressed: _load,
                child: const Text('订单加载失败，点击重试'),
              ),
            )
          : _buildOrder(context, _order!),
    );
  }

  Widget _buildOrder(BuildContext context, TradeOrder order) {
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
                Text('${order.shopName} · 订单 ${order.orderNo}'),
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
                _DetailRow(label: '数量', value: '${order.quantity}'),
                _DetailRow(
                  label: '单价',
                  value: formatMoney(order.unitPrice, order.currency),
                ),
                _DetailRow(
                  label: '实付',
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
            label: const Text('发起支付'),
          ),
          OutlinedButton(
            key: const Key('order-cancel-button'),
            onPressed: _acting || _confirmingCancel ? null : _cancel,
            child: const Text('取消订单'),
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
            label: const Text('申请退款'),
          ),
        ],
        if (order.refund != null) ...[
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              title: Text('退款：${order.refund!.statusText}'),
              subtitle: Text(order.refund!.reason),
            ),
          ),
        ],
        if (order.coupons.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            '关联券码',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('券码已复制')));
    } finally {
      if (mounted) setState(() => _copyingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('券详情')),
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
                  Text('券码详情加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('coupon-detail-retry'),
                    onPressed: _reloading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(_reloading ? '处理中...' : '重试'),
                  ),
                ],
              ),
            );
          }
          final detail = snapshot.data;
          final coupon = detail ?? widget.initialCoupon!;
          final usable = detail?.usable;
          final verifyHint = detail?.verifyHint ?? '券码由商户核销；用户端不提供自助核销，避免误操作。';
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
                            : '${coupon.statusText} · ${usable ? '可核销' : '不可核销'}',
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
                        label: Text(_copyingCode ? '复制中...' : '复制券码'),
                      ),
                      if (qrImageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Image.network(
                          qrImageUrl,
                          key: const Key('coupon-qr-image'),
                          width: 220,
                          height: 220,
                          errorBuilder: (_, _, _) => const Text('二维码加载失败'),
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
                        '有效期至 ${coupon.expireAt.isEmpty ? '不限期' : coupon.expireAt}',
                      ),
                      if (detail != null &&
                          (detail.validStart.isNotEmpty ||
                              detail.validEnd.isNotEmpty))
                        Text(
                          '团购有效期 ${detail.validStart.isEmpty ? '—' : detail.validStart} ~ ${detail.validEnd.isEmpty ? '—' : detail.validEnd}',
                        ),
                      if (detail != null && detail.verifyAt.isNotEmpty)
                        Text('核销时间 ${detail.verifyAt}'),
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
                        const Text(
                          '使用规则',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(detail.rules.isEmpty ? '暂无补充规则' : detail.rules),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('请向商户出示券码'),
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
                        '详情刷新失败：${snapshot.error}',
                        style: const TextStyle(color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('coupon-detail-fallback-retry'),
                        onPressed: _reloading ? null : _reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(_reloading ? '处理中...' : '重新加载完整详情'),
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
