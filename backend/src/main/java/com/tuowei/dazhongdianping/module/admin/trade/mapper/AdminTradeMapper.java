package com.tuowei.dazhongdianping.module.admin.trade.mapper;

import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderQuery;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.ChannelStatementBatchRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.ChannelStatementItemRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.ChannelStatementMatchRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminTradeMapper {

    long countOrders(@Param("region") String region,
                     @Param("query") AdminOrderQuery query,
                     @Param("dateToExclusive") LocalDate dateToExclusive,
                     @Param("allCities") boolean allCities,
                     @Param("cityIds") Set<Long> cityIds,
                     @Param("shopIds") Set<Long> shopIds);

    List<AdminOrderRow> selectOrders(@Param("region") String region,
                                     @Param("query") AdminOrderQuery query,
                                     @Param("dateToExclusive") LocalDate dateToExclusive,
                                     @Param("allCities") boolean allCities,
                                     @Param("cityIds") Set<Long> cityIds,
                                     @Param("shopIds") Set<Long> shopIds);

    AdminOrderRow selectOrderById(@Param("region") String region,
                                  @Param("id") Long id,
                                  @Param("allCities") boolean allCities,
                                  @Param("cityIds") Set<Long> cityIds,
                                  @Param("shopIds") Set<Long> shopIds);

    RefundRow selectRefundByOrder(@Param("orderId") Long orderId);

    int approveRefund(@Param("orderId") Long orderId,
                      @Param("adminId") Long adminId,
                      @Param("reason") String reason);

    int markRefundProcessing(@Param("orderId") Long orderId,
                             @Param("adminId") Long adminId,
                             @Param("reason") String reason);

    int rejectRefund(@Param("orderId") Long orderId,
                     @Param("adminId") Long adminId,
                     @Param("reason") String reason);

    int markOrderRefunded(@Param("orderId") Long orderId);

    int markCouponsRefunded(@Param("orderId") Long orderId);

    int restoreDealStock(@Param("dealId") Long dealId, @Param("quantity") Integer quantity);

    ChannelStatementBatchRow selectStatementBatchByHash(
            @Param("region") String region,
            @Param("channel") String channel,
            @Param("fileSha256") String fileSha256
    );

    void insertStatementBatch(ChannelStatementBatchRow row);

    int updateStatementBatchSummary(ChannelStatementBatchRow row);

    void insertStatementItem(ChannelStatementItemRow row);

    ChannelStatementMatchRow selectStatementMatch(
            @Param("region") String region,
            @Param("channel") String channel,
            @Param("channelTransactionId") String channelTransactionId
    );

    ChannelStatementMatchRow selectStatementMatchByOrderNo(
            @Param("region") String region,
            @Param("channel") String channel,
            @Param("orderNo") String orderNo,
            @Param("bizType") String bizType
    );

    long countStatementBatches(@Param("region") String region);

    List<ChannelStatementBatchRow> selectStatementBatches(
            @Param("region") String region,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    ChannelStatementBatchRow selectStatementBatchById(
            @Param("region") String region,
            @Param("batchId") Long batchId
    );

    long countStatementItems(
            @Param("batchId") Long batchId,
            @Param("reconcileStatus") String reconcileStatus
    );

    List<ChannelStatementItemRow> selectStatementItems(
            @Param("batchId") Long batchId,
            @Param("reconcileStatus") String reconcileStatus,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );
}
