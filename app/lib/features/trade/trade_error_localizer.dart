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
      '订单已超时，请重新下单': strings.orderPaymentExpired,
      '秒杀已售罄': strings.seckillSoldOut,
      '已参与过该秒杀': strings.seckillLimitReached,
      '不在秒杀活动时间内': strings.seckillUnavailable,
      '秒杀活动不存在': strings.seckillUnavailable,
      '秒杀套餐已失效': strings.seckillUnavailable,
      '秒杀价格已失效': strings.seckillUnavailable,
      '拼团不存在': strings.groupBuyUnavailable,
      '拼团已结束': strings.groupBuyUnavailable,
      '拼团已过期': strings.groupBuyUnavailable,
      '拼团已满员或已结束': strings.groupBuyUnavailable,
      '已参加该拼团活动': strings.groupBuyUnavailable,
      '不在拼团活动时间内': strings.groupBuyUnavailable,
      '拼团活动不存在': strings.groupBuyUnavailable,
      '拼团套餐已失效': strings.groupBuyUnavailable,
      '拼团价格已失效': strings.groupBuyUnavailable,
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
