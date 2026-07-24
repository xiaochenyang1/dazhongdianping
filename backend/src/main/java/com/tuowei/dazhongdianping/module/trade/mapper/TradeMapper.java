package com.tuowei.dazhongdianping.module.trade.mapper;

import com.tuowei.dazhongdianping.module.trade.model.CouponRow;
import com.tuowei.dazhongdianping.module.trade.model.DealItemRow;
import com.tuowei.dazhongdianping.module.trade.model.DealRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import java.math.BigDecimal;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface TradeMapper {

    List<DealRow> selectShopDeals(@Param("shopId") Long shopId, @Param("region") String region);

    DealRow selectDeal(@Param("dealId") Long dealId, @Param("region") String region);

    List<DealItemRow> selectDealItems(@Param("dealId") Long dealId);

    int decrementDealStock(@Param("dealId") Long dealId, @Param("quantity") Integer quantity);

    int restoreDealStock(@Param("dealId") Long dealId, @Param("quantity") Integer quantity);

    void insertOrder(OrderRow row);

    OrderRow selectUserOrder(
            @Param("orderId") Long orderId,
            @Param("userId") Long userId,
            @Param("region") String region
    );

    OrderRow selectOrderByNo(@Param("orderNo") String orderNo);

    List<OrderRow> selectUserOrders(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("payStatus") Integer payStatus,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    long countUserOrders(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("payStatus") Integer payStatus
    );

    int closeOrder(@Param("orderId") Long orderId, @Param("userId") Long userId);

    List<OrderRow> selectExpiredUnpaidOrders(@Param("limit") Integer limit);

    int closeExpiredUnpaidOrder(@Param("orderId") Long orderId);

    List<PaymentRow> selectStalePendingPayments(@Param("limit") Integer limit);

    int markPaymentFailed(@Param("paymentId") Long paymentId, @Param("rawResponse") String rawResponse);

    void insertPayment(PaymentRow row);

    PaymentRow selectPayment(@Param("orderId") Long orderId);

    PaymentRow selectPaymentByTxn(@Param("channel") String channel, @Param("channelTxn") String channelTxn);

    int markPaymentSuccess(PaymentRow row);

    int markOrderPaid(@Param("orderId") Long orderId, @Param("channel") String channel);

    long countOrderCoupons(@Param("orderId") Long orderId);

    void insertCoupon(CouponRow row);

    List<CouponRow> selectOrderCoupons(@Param("orderId") Long orderId, @Param("userId") Long userId);

    long countCoupons(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("status") Integer status
    );

    List<CouponRow> selectCoupons(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    CouponRow selectMerchantCoupon(
            @Param("code") String code,
            @Param("merchantId") Long merchantId,
            @Param("region") String region
    );

    int verifyMerchantCoupon(
            @Param("code") String code,
            @Param("merchantId") Long merchantId,
            @Param("operatorId") Long operatorId,
            @Param("region") String region
    );

    long countUsedCoupons(@Param("orderId") Long orderId);

    RefundRow selectRefundByOrder(@Param("orderId") Long orderId);

    void insertRefund(
            @Param("orderId") Long orderId,
            @Param("amount") BigDecimal amount,
            @Param("reason") String reason
    );

    int markOrderRefunded(@Param("orderId") Long orderId);

    int markCouponsRefunded(@Param("orderId") Long orderId);
}
