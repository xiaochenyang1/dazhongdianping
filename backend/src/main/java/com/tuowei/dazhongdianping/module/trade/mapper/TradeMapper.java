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

    DealRow selectDealForUpdate(@Param("dealId") Long dealId, @Param("region") String region);

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

    OrderRow selectOrderById(@Param("orderId") Long orderId);

    OrderRow selectOrderForUpdate(@Param("orderId") Long orderId);

    int markInventoryReleased(@Param("orderId") Long orderId);

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

    PaymentRow selectPaymentForUpdate(@Param("orderId") Long orderId);

    PaymentRow selectPaymentByTxnForUpdate(@Param("channel") String channel, @Param("channelTxn") String channelTxn);

    PaymentRow selectPaymentByTxn(@Param("channel") String channel, @Param("channelTxn") String channelTxn);

    int markPaymentSuccess(PaymentRow row);

    int markOrderPaid(@Param("orderId") Long orderId, @Param("channel") String channel);

    int markClosedOrderPaid(@Param("orderId") Long orderId, @Param("channel") String channel);

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

    CouponRow selectUserCouponByCode(
            @Param("code") String code,
            @Param("userId") Long userId,
            @Param("region") String region
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

    List<CouponRow> selectOrderCouponsForUpdate(@Param("orderId") Long orderId);

    CouponRow selectCouponForUpdate(@Param("couponId") Long couponId);

    RefundRow selectRefundByOrder(@Param("orderId") Long orderId);

    RefundRow selectRefundForUpdate(@Param("orderId") Long orderId);

    RefundRow selectRefundByChannelTxn(
            @Param("channel") String channel,
            @Param("channelRefundTxn") String channelRefundTxn
    );

    void insertRefund(
            @Param("orderId") Long orderId,
            @Param("amount") BigDecimal amount,
            @Param("reason") String reason
    );

    int markOrderRefunded(@Param("orderId") Long orderId);

    int recordRefundChannelResult(
            @Param("refundId") Long refundId,
            @Param("channel") String channel,
            @Param("channelRefundTxn") String channelRefundTxn,
            @Param("channelStatus") String channelStatus,
            @Param("channelFailureReason") String channelFailureReason
    );

    int updateRefundChannelState(
            @Param("refundId") Long refundId,
            @Param("status") Integer status,
            @Param("channelStatus") String channelStatus,
            @Param("channelFailureReason") String channelFailureReason
    );

    int recordFailedAutomaticRefundReview(
            @Param("refundId") Long refundId,
            @Param("auditBy") Long auditBy,
            @Param("auditReason") String auditReason
    );

    int confirmFailedAutomaticRefund(
            @Param("refundId") Long refundId,
            @Param("auditBy") Long auditBy,
            @Param("auditReason") String auditReason
    );

    List<RefundRow> selectProcessingRefunds(@Param("limit") Integer limit);

    List<RefundRow> selectUnsubmittedAutoRefunds(@Param("limit") Integer limit);

    void insertAutomaticRefund(
            @Param("orderId") Long orderId,
            @Param("amount") BigDecimal amount,
            @Param("channel") String channel,
            @Param("refundType") String refundType,
            @Param("reason") String reason);

    int promoteRefundToAutomatic(
            @Param("orderId") Long orderId,
            @Param("channel") String channel,
            @Param("refundType") String refundType,
            @Param("reason") String reason);

    int recordAutomaticRefundRetry(@Param("refundId") Long refundId);

    int markCouponsRefunded(@Param("orderId") Long orderId);

    List<CouponRow> selectExpiredActiveCoupons(@Param("limit") Integer limit);

    int markCouponExpired(@Param("couponId") Long couponId);

    List<CouponRow> selectDueCouponReminders(
            @Param("today") java.time.LocalDate today,
            @Param("windowEnd") java.time.LocalDate windowEnd,
            @Param("limit") Integer limit
    );

    int markCouponRemindStatus(
            @Param("couponId") Long couponId,
            @Param("expectedStatus") Integer expectedStatus,
            @Param("nextStatus") Integer nextStatus
    );
}
