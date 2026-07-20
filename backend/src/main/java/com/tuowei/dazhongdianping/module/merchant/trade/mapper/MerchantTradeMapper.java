package com.tuowei.dazhongdianping.module.merchant.trade.mapper;

import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantDealItemRequest;
import com.tuowei.dazhongdianping.module.trade.model.DealItemRow;
import com.tuowei.dazhongdianping.module.trade.model.DealRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import java.time.LocalDate;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MerchantTradeMapper {

    long countDeals(@Param("merchantId") Long merchantId,
                    @Param("region") String region,
                    @Param("shopId") Long shopId,
                    @Param("shopIds") List<Long> shopIds,
                    @Param("auditStatus") Integer auditStatus,
                    @Param("status") Integer status);

    List<DealRow> selectDeals(@Param("merchantId") Long merchantId,
                              @Param("region") String region,
                              @Param("shopId") Long shopId,
                              @Param("shopIds") List<Long> shopIds,
                              @Param("auditStatus") Integer auditStatus,
                              @Param("status") Integer status,
                              @Param("limit") Integer limit,
                              @Param("offset") Integer offset);

    DealRow selectDeal(@Param("dealId") Long dealId,
                       @Param("merchantId") Long merchantId,
                       @Param("region") String region);

    List<DealItemRow> selectDealItems(@Param("dealId") Long dealId);

    void insertDeal(DealRow row);

    int updateDeal(DealRow row);

    void deleteDealItems(@Param("dealId") Long dealId);

    void insertDealItems(@Param("dealId") Long dealId,
                         @Param("items") List<MerchantDealItemRequest> items);

    int changeDealStatus(@Param("dealId") Long dealId,
                         @Param("merchantId") Long merchantId,
                         @Param("region") String region,
                         @Param("status") Integer status);

    long countPaidOrders(@Param("dealId") Long dealId);

    long countOrders(@Param("merchantId") Long merchantId,
                     @Param("region") String region,
                     @Param("shopId") Long shopId,
                     @Param("shopIds") List<Long> shopIds,
                     @Param("payStatus") Integer payStatus,
                     @Param("refundStatus") Integer refundStatus,
                     @Param("orderNo") String orderNo,
                     @Param("dateFrom") LocalDate dateFrom,
                     @Param("dateToExclusive") LocalDate dateToExclusive);

    List<OrderRow> selectOrders(@Param("merchantId") Long merchantId,
                                @Param("region") String region,
                                @Param("shopId") Long shopId,
                                @Param("shopIds") List<Long> shopIds,
                                @Param("payStatus") Integer payStatus,
                                @Param("refundStatus") Integer refundStatus,
                                @Param("orderNo") String orderNo,
                                @Param("dateFrom") LocalDate dateFrom,
                                @Param("dateToExclusive") LocalDate dateToExclusive,
                                @Param("limit") Integer limit,
                                @Param("offset") Integer offset);

    OrderRow selectOrder(@Param("orderId") Long orderId,
                         @Param("merchantId") Long merchantId,
                         @Param("region") String region);

    RefundRow selectRefund(@Param("orderId") Long orderId);

    int approveRefund(@Param("orderId") Long orderId,
                      @Param("operatorId") Long operatorId,
                      @Param("reason") String reason);

    int rejectRefund(@Param("orderId") Long orderId,
                     @Param("operatorId") Long operatorId,
                     @Param("reason") String reason);

    int markOrderRefunded(@Param("orderId") Long orderId);

    int markCouponsRefunded(@Param("orderId") Long orderId);

    int restoreDealStock(@Param("dealId") Long dealId,
                         @Param("quantity") Integer quantity);

    void insertOperationLog(@Param("merchantId") Long merchantId,
                            @Param("operatorId") Long operatorId,
                            @Param("action") String action,
                            @Param("targetType") String targetType,
                            @Param("targetId") Long targetId,
                            @Param("detail") String detail);
}
