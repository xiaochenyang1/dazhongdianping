package com.tuowei.dazhongdianping.module.admin.trade.mapper;

import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderQuery;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import java.time.LocalDate;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminTradeMapper {

    long countOrders(@Param("region") String region,
                     @Param("query") AdminOrderQuery query,
                     @Param("dateToExclusive") LocalDate dateToExclusive);

    List<AdminOrderRow> selectOrders(@Param("region") String region,
                                     @Param("query") AdminOrderQuery query,
                                     @Param("dateToExclusive") LocalDate dateToExclusive);

    AdminOrderRow selectOrderById(@Param("region") String region, @Param("id") Long id);

    RefundRow selectRefundByOrder(@Param("orderId") Long orderId);

    int approveRefund(@Param("orderId") Long orderId,
                      @Param("adminId") Long adminId,
                      @Param("reason") String reason);

    int rejectRefund(@Param("orderId") Long orderId,
                     @Param("adminId") Long adminId,
                     @Param("reason") String reason);

    int markOrderRefunded(@Param("orderId") Long orderId);

    int markCouponsRefunded(@Param("orderId") Long orderId);

    int restoreDealStock(@Param("dealId") Long dealId, @Param("quantity") Integer quantity);
}
