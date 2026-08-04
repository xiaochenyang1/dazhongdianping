package com.tuowei.dazhongdianping.module.admin.merchant.mapper;

import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantRow;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorRow;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperationLogQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperationLogRow;
import java.util.List;
import java.util.Set;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminMerchantManagementMapper {

    long countMerchants(@Param("query") AdminMerchantQuery query,
                        @Param("region") String region,
                        @Param("allCities") boolean allCities,
                        @Param("cityIds") Set<Long> cityIds,
                        @Param("shopIds") Set<Long> shopIds);

    List<AdminMerchantRow> selectMerchants(@Param("query") AdminMerchantQuery query,
                                           @Param("region") String region,
                                           @Param("allCities") boolean allCities,
                                           @Param("cityIds") Set<Long> cityIds,
                                           @Param("shopIds") Set<Long> shopIds);

    AdminMerchantRow selectMerchantById(@Param("merchantId") Long merchantId,
                                        @Param("region") String region,
                                        @Param("allCities") boolean allCities,
                                        @Param("cityIds") Set<Long> cityIds,
                                        @Param("shopIds") Set<Long> shopIds);

    int updateMerchantStatus(@Param("merchantId") Long merchantId,
                             @Param("region") String region,
                             @Param("expectedStatus") Integer expectedStatus,
                             @Param("status") Integer status,
                             @Param("allCities") boolean allCities,
                             @Param("cityIds") Set<Long> cityIds,
                             @Param("shopIds") Set<Long> shopIds);

    long countMerchantOperators(@Param("merchantId") Long merchantId,
                                @Param("region") String region,
                                @Param("query") AdminMerchantOperatorQuery query,
                                @Param("allCities") boolean allCities,
                                @Param("cityIds") Set<Long> cityIds,
                                @Param("shopIds") Set<Long> shopIds);

    List<AdminMerchantOperatorRow> selectMerchantOperators(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("query") AdminMerchantOperatorQuery query,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds
    );

    AdminMerchantOperatorRow selectMerchantOperatorById(@Param("merchantId") Long merchantId,
                                                        @Param("operatorId") Long operatorId,
                                                        @Param("region") String region,
                                                        @Param("allCities") boolean allCities,
                                                        @Param("cityIds") Set<Long> cityIds,
                                                        @Param("shopIds") Set<Long> shopIds);

    List<String> selectMerchantOperatorRoleNames(@Param("operatorId") Long operatorId);

    List<Long> selectMerchantOperatorShopIds(@Param("operatorId") Long operatorId);

    int updateMerchantOperatorStatus(@Param("merchantId") Long merchantId,
                                     @Param("operatorId") Long operatorId,
                                     @Param("region") String region,
                                     @Param("expectedStatus") Integer expectedStatus,
                                     @Param("status") Integer status,
                                     @Param("allCities") boolean allCities,
                                     @Param("cityIds") Set<Long> cityIds,
                                     @Param("shopIds") Set<Long> shopIds);

    long countMerchantOperationLogs(@Param("merchantId") Long merchantId,
                                    @Param("region") String region,
                                    @Param("query") AdminMerchantOperationLogQuery query,
                                    @Param("allCities") boolean allCities,
                                    @Param("cityIds") Set<Long> cityIds,
                                    @Param("shopIds") Set<Long> shopIds);

    List<AdminMerchantOperationLogRow> selectMerchantOperationLogs(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("query") AdminMerchantOperationLogQuery query,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds
    );
}
