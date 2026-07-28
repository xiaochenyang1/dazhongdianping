package com.tuowei.dazhongdianping.module.admin.management.mapper;

import com.tuowei.dazhongdianping.module.admin.management.model.AdminImportBatchQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopListQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopRow;
import com.tuowei.dazhongdianping.module.admin.management.model.ImportBatchRow;
import com.tuowei.dazhongdianping.module.admin.management.model.MerchantRow;
import java.util.List;
import java.util.Set;
import org.apache.ibatis.annotations.Param;

public interface AdminManagementMapper {

    MerchantRow selectMerchantByAccount(@Param("account") String account);

    MerchantRow selectMerchantById(@Param("merchantId") Long merchantId);

    void insertMerchant(MerchantRow merchantRow);

    long countAdminShops(@Param("query") AdminShopListQuery query,
                         @Param("allCities") boolean allCities,
                         @Param("cityIds") Set<Long> cityIds,
                         @Param("shopIds") Set<Long> shopIds);

    List<AdminShopRow> selectAdminShops(@Param("query") AdminShopListQuery query,
                                        @Param("allCities") boolean allCities,
                                        @Param("cityIds") Set<Long> cityIds,
                                        @Param("shopIds") Set<Long> shopIds);

    AdminShopRow selectAdminShopDetail(@Param("shopId") Long shopId,
                                       @Param("region") String region,
                                       @Param("allCities") boolean allCities,
                                       @Param("cityIds") Set<Long> cityIds,
                                       @Param("shopIds") Set<Long> shopIds);

    void insertShop(AdminShopRow adminShopRow);

    int updateShop(@Param("shop") AdminShopRow adminShopRow,
                   @Param("expectedRegion") String expectedRegion,
                   @Param("expectedCityId") Long expectedCityId);

    int softDeleteShop(@Param("shopId") Long shopId,
                       @Param("region") String region,
                       @Param("expectedCityId") Long expectedCityId);

    void insertImportBatch(ImportBatchRow batchRow);

    int updateImportBatch(ImportBatchRow batchRow);

    long countImportBatches(@Param("query") AdminImportBatchQuery query,
                            @Param("adminId") Long adminId,
                            @Param("ownOnly") boolean ownOnly);

    List<ImportBatchRow> selectImportBatches(@Param("query") AdminImportBatchQuery query,
                                             @Param("adminId") Long adminId,
                                             @Param("ownOnly") boolean ownOnly);
}
