import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeTradeError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '团购不存在': strings.tradeErrorDealNotFound,
      '团购已过期': strings.tradeErrorDealExpired,
      '团购库存不足': strings.tradeErrorDealOutOfStock,
      '订单不存在': strings.tradeErrorOrderNotFound,
      '订单当前不可支付': strings.tradeErrorOrderPaymentUnavailable,
      '订单当前不可取消': strings.tradeErrorOrderCancelUnavailable,
      '订单当前不可退款': strings.tradeErrorOrderRefundUnavailable,
      '存在已核销券，不能整单退款': strings.tradeErrorRefundUsedCoupons,
      '订单已有退款申请': strings.tradeErrorRefundExists,
      '券码不能为空': strings.tradeErrorCouponCodeRequired,
      '券码不存在': strings.tradeErrorCouponNotFound,
      '支付渠道尚未配置': strings.tradeErrorPaymentChannelUnavailable,
      ...overrides,
    },
  );
}
