package com.tuowei.dazhongdianping.module.admin.merchant.mapper;

import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantRow;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminMerchantManagementMapper {

    long countMerchants(@Param("query") AdminMerchantQuery query,
                        @Param("region") String region);

    List<AdminMerchantRow> selectMerchants(@Param("query") AdminMerchantQuery query,
                                           @Param("region") String region);

    AdminMerchantRow selectMerchantById(@Param("merchantId") Long merchantId,
                                        @Param("region") String region);

    int updateMerchantStatus(@Param("merchantId") Long merchantId,
                             @Param("region") String region,
                             @Param("expectedStatus") Integer expectedStatus,
                             @Param("status") Integer status);

    long countMerchantOperators(@Param("merchantId") Long merchantId,
                                @Param("region") String region,
                                @Param("query") AdminMerchantOperatorQuery query);

    List<AdminMerchantOperatorRow> selectMerchantOperators(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("query") AdminMerchantOperatorQuery query
    );

    AdminMerchantOperatorRow selectMerchantOperatorById(@Param("merchantId") Long merchantId,
                                                        @Param("operatorId") Long operatorId,
                                                        @Param("region") String region);

    List<String> selectMerchantOperatorRoleNames(@Param("operatorId") Long operatorId);

    List<Long> selectMerchantOperatorShopIds(@Param("operatorId") Long operatorId);

    int updateMerchantOperatorStatus(@Param("merchantId") Long merchantId,
                                     @Param("operatorId") Long operatorId,
                                     @Param("region") String region,
                                     @Param("expectedStatus") Integer expectedStatus,
                                     @Param("status") Integer status);
}
