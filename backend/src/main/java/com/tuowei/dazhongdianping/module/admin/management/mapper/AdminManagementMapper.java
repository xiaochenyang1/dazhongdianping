package com.tuowei.dazhongdianping.module.admin.management.mapper;

import com.tuowei.dazhongdianping.module.admin.management.model.AdminImportBatchQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopListQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopRow;
import com.tuowei.dazhongdianping.module.admin.management.model.ImportBatchRow;
import com.tuowei.dazhongdianping.module.admin.management.model.MerchantRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminManagementMapper {

    MerchantRow selectMerchantByAccount(@Param("account") String account);

    MerchantRow selectMerchantById(@Param("merchantId") Long merchantId);

    void insertMerchant(MerchantRow merchantRow);

    long countAdminShops(AdminShopListQuery query);

    List<AdminShopRow> selectAdminShops(AdminShopListQuery query);

    AdminShopRow selectAdminShopDetail(@Param("shopId") Long shopId,
                                       @Param("region") String region);

    void insertShop(AdminShopRow adminShopRow);

    int updateShop(AdminShopRow adminShopRow);

    int softDeleteShop(@Param("shopId") Long shopId,
                       @Param("region") String region);

    void insertImportBatch(ImportBatchRow batchRow);

    int updateImportBatch(ImportBatchRow batchRow);

    long countImportBatches(AdminImportBatchQuery query);

    List<ImportBatchRow> selectImportBatches(AdminImportBatchQuery query);
}
