package com.tuowei.dazhongdianping.module.admin.merchant.mapper;

import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantRow;
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
}
