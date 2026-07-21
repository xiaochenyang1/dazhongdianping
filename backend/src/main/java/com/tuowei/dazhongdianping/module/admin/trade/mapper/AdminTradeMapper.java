package com.tuowei.dazhongdianping.module.admin.trade.mapper;

import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderQuery;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderRow;
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
}
