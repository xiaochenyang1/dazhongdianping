package com.tuowei.dazhongdianping.module.openapi.mapper;

import com.tuowei.dazhongdianping.module.openapi.model.OpenApiCredential;
import com.tuowei.dazhongdianping.module.openapi.model.OpenApiKeyRow;
import com.tuowei.dazhongdianping.module.openapi.model.OpenAppRow;
import com.tuowei.dazhongdianping.module.openapi.model.OpenReviewRow;
import com.tuowei.dazhongdianping.module.openapi.model.OpenShopRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface OpenApiMapper {

    void insertApp(OpenAppRow row);

    void insertKey(OpenApiKeyRow row);

    List<OpenAppRow> selectApps(@Param("region") String region);

    OpenAppRow selectApp(@Param("id") Long id, @Param("region") String region);

    int updateAppStatus(@Param("id") Long id, @Param("region") String region, @Param("status") int status);

    /** 列表用，不查询 secret。 */
    List<OpenApiKeyRow> selectKeyIdsByAppIds(@Param("appIds") List<Long> appIds);

    OpenApiCredential selectCredential(@Param("keyId") String keyId);

    List<OpenShopRow> selectPublicShops(@Param("region") String region, @Param("limit") int limit);

    List<OpenReviewRow> selectPublicReviews(
            @Param("region") String region, @Param("shopId") Long shopId, @Param("limit") int limit);
}
