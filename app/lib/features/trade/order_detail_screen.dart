import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.repository,
    required this.orderId,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final TradeRepository repository;
  final int orderId;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  TradeOrder? _order;
  String? _error;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    final confirmed = await showDialog<bool>(
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
    if (confirmed != true || !mounted) return;
    await _runAction(
      () => widget.repository.cancelOrder(widget.orderId),
      '订单已取消',
    );
  }

  Future<void> _refund() async {
    final controller = TextEditingController(text: '行程有变');
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('申请退款'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '退款原因'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('提交申请'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty || !mounted) return;
    await _runAction(
      () => widget.repository.refundOrder(widget.orderId, reason: reason),
      '退款申请已提交',
    );
  }

  Future<void> _pay() async {
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

  Future<void> _runAction(
    Future<TradeOrder> Function() action,
    String successMessage,
  ) async {
    setState(() => _acting = true);
    try {
      final order = await action();
      if (!mounted) return;
      setState(() => _order = order);
      _showMessage(successMessage);
    } catch (error) {
      if (mounted) _showMessage('操作失败：$error');
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
            onPressed: _acting ? null : _pay,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('发起支付'),
          ),
          OutlinedButton(
            onPressed: _acting ? null : _cancel,
            child: const Text('取消订单'),
          ),
        ],
        if (order.payStatus == 1 &&
            order.status == 1 &&
            order.refund == null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _acting ? null : _refund,
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CouponDetailScreen(coupon: coupon),
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

class CouponDetailScreen extends StatelessWidget {
  const CouponDetailScreen({super.key, required this.coupon});
  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('券详情')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(coupon.statusText),
                  const SizedBox(height: 12),
                  SelectableText(
                    coupon.code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
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
                  Text('有效期至 ${coupon.expireAt}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('请向商户出示券码'),
              subtitle: Text('券码由商户核销；用户端不提供自助核销，避免误操作。'),
            ),
          ),
        ],
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
