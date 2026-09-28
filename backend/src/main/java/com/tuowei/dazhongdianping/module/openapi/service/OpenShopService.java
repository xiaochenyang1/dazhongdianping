package com.tuowei.dazhongdianping.module.openapi.service;

import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.openapi.mapper.OpenApiMapper;
import com.tuowei.dazhongdianping.module.openapi.model.OpenReviewRow;
import com.tuowei.dazhongdianping.module.openapi.model.OpenShopRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

/** 开放平台只读门店与公开点评。区域来自已验签应用，不信任客户端 X-Region。 */
@Service
public class OpenShopService {

    private final OpenApiMapper mapper;

    public OpenShopService(OpenApiMapper mapper) {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> shops(Integer limit) {
        String region = RegionContext.getRegion().name();
        return mapper.selectPublicShops(region, bounded(limit)).stream().map(this::shop).toList();
    }

    public List<Map<String, Object>> reviews(Long shopId, Integer limit) {
        if (shopId != null && shopId < 1) {
            throw new IllegalArgumentException("shopId 无效");
        }
        String region = RegionContext.getRegion().name();
        return mapper.selectPublicReviews(region, shopId, bounded(limit)).stream().map(this::review).toList();
    }

    private int bounded(Integer limit) {
        int n = limit == null ? 10 : limit;
        if (n < 1 || n > 20) {
            throw new IllegalArgumentException("limit 必须在 1 到 20 之间");
        }
        return n;
    }

    private Map<String, Object> shop(OpenShopRow row) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", row.getId());
        m.put("name", row.getName());
        m.put("address", row.getAddress());
        m.put("score", row.getScore());
        return m;
    }

    private Map<String, Object> review(OpenReviewRow row) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", row.getId());
        m.put("shopId", row.getShopId());
        m.put("score", row.getScore());
        m.put("content", row.getContent());
        return m;
    }
}
