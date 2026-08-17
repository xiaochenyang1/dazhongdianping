package com.tuowei.dazhongdianping.module.search.mapper;

import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskRow;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncOverviewRow;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchSyncTaskQuery;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import org.apache.ibatis.annotations.Param;

public interface SearchIndexSyncMapper {

    int enqueueShopSync(@Param("shopId") Long shopId);

    List<ShopSearchSyncTaskRow> selectDueShopSyncTasks(
            @Param("now") LocalDateTime now,
            @Param("staleBefore") LocalDateTime staleBefore,
            @Param("limit") int limit);

    int claimShopSyncTask(
            @Param("shopId") Long shopId,
            @Param("version") Long version,
            @Param("now") LocalDateTime now,
            @Param("staleBefore") LocalDateTime staleBefore);

    int completeShopSyncTask(
            @Param("shopId") Long shopId,
            @Param("version") Long version);

    int rescheduleShopSyncTask(
            @Param("shopId") Long shopId,
            @Param("version") Long version,
            @Param("nextRetryAt") LocalDateTime nextRetryAt,
            @Param("lastError") String lastError);

    ShopSearchSyncOverviewRow selectAdminSyncOverview(
            @Param("region") String region,
            @Param("now") LocalDateTime now,
            @Param("staleBefore") LocalDateTime staleBefore,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    long countAdminShopSyncTasks(
            @Param("query") ShopSearchSyncTaskQuery query,
            @Param("region") String region,
            @Param("staleBefore") LocalDateTime staleBefore,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    List<ShopSearchSyncTaskRow> selectAdminShopSyncTasks(
            @Param("query") ShopSearchSyncTaskQuery query,
            @Param("region") String region,
            @Param("staleBefore") LocalDateTime staleBefore,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    int retryAdminShopSyncTask(
            @Param("shopId") Long shopId,
            @Param("region") String region,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    int retryAdminFailedShopSyncTasks(
            @Param("region") String region,
            @Param("staleBefore") LocalDateTime staleBefore,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);
}
