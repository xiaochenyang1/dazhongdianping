package com.tuowei.dazhongdianping.module.admin.dashboard.mapper;

import java.util.List;
import java.util.Set;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminDashboardMapper {

    long countShops(@Param("region") String region,
                    @Param("allCities") boolean allCities,
                    @Param("cityIds") Set<Long> cityIds,
                    @Param("shopIds") Set<Long> shopIds);

    long countImportBatches(@Param("region") String region);

    long countPaidOrders(@Param("region") String region,
                         @Param("allCities") boolean allCities,
                         @Param("cityIds") Set<Long> cityIds,
                         @Param("shopIds") Set<Long> shopIds);

    long countPendingRefunds(@Param("region") String region,
                             @Param("allCities") boolean allCities,
                             @Param("cityIds") Set<Long> cityIds,
                             @Param("shopIds") Set<Long> shopIds);

    long countPendingAuditTasks(@Param("region") String region,
                                @Param("allowedBizTypes") List<Integer> allowedBizTypes);

    long countUsers();
}
