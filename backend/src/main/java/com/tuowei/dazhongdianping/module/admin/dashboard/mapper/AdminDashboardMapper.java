package com.tuowei.dazhongdianping.module.admin.dashboard.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminDashboardMapper {

    long countShops(@Param("region") String region);

    long countImportBatches(@Param("region") String region);

    long countPaidOrders(@Param("region") String region);

    long countPendingRefunds(@Param("region") String region);

    long countPendingAuditTasks(@Param("region") String region,
                                @Param("allowedBizTypes") List<Integer> allowedBizTypes);

    long countUsers();
}
