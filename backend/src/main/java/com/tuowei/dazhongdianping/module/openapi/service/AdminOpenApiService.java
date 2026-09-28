package com.tuowei.dazhongdianping.module.openapi.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.openapi.mapper.OpenApiMapper;
import com.tuowei.dazhongdianping.module.openapi.model.OpenApiKeyRow;
import com.tuowei.dazhongdianping.module.openapi.model.OpenAppRow;
import com.tuowei.dazhongdianping.module.openapi.model.request.OpenAppCreateRequest;
import com.tuowei.dazhongdianping.module.openapi.model.request.OpenAppStatusRequest;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 平台侧开放应用管理。密钥明文只在创建响应里出现一次。 */
@Service
public class AdminOpenApiService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final OpenApiMapper mapper;

    public AdminOpenApiService(OpenApiMapper mapper) {
        this.mapper = mapper;
    }

    @Transactional
    public Map<String, Object> create(OpenAppCreateRequest req) {
        String region = region();
        OpenAppRow app = new OpenAppRow();
        app.setRegion(region);
        app.setName(req.name().trim());
        app.setOwnerMerchantId(req.ownerMerchantId());
        app.setStatus(1);
        mapper.insertApp(app);

        String keyId = "ak" + randomHex(16);
        String secret = randomHex(32);
        OpenApiKeyRow key = new OpenApiKeyRow();
        key.setAppId(app.getId());
        key.setKeyId(keyId);
        // secret_hash 列是内部密钥库：这里写入原始 secret，不哈希，HMAC 验签要用同一份明文。
        key.setSecretHash(secret);
        key.setStatus(1);
        mapper.insertKey(key);

        OpenAppRow stored = mapper.selectApp(app.getId(), region);
        Map<String, Object> body = appView(stored, List.of(keyId));
        body.put("keyId", keyId);
        body.put("secret", secret);
        return body;
    }

    public List<Map<String, Object>> apps() {
        String region = region();
        List<OpenAppRow> apps = mapper.selectApps(region);
        if (apps.isEmpty()) {
            return List.of();
        }
        List<Long> ids = apps.stream().map(OpenAppRow::getId).toList();
        Map<Long, List<String>> keyIds = new LinkedHashMap<>();
        for (OpenApiKeyRow key : mapper.selectKeyIdsByAppIds(ids)) {
            keyIds.computeIfAbsent(key.getAppId(), ignored -> new ArrayList<>()).add(key.getKeyId());
        }
        return apps.stream()
                .map(app -> appView(app, keyIds.getOrDefault(app.getId(), List.of())))
                .toList();
    }

    @Transactional
    public Map<String, Object> updateStatus(Long id, OpenAppStatusRequest req) {
        String region = region();
        OpenAppRow app = mapper.selectApp(id, region);
        if (app == null) {
            throw new NotFoundException("开放应用不存在");
        }
        if (mapper.updateAppStatus(id, region, req.status()) == 0) {
            throw new NotFoundException("开放应用不存在");
        }
        OpenAppRow stored = mapper.selectApp(id, region);
        List<String> keyIds = mapper.selectKeyIdsByAppIds(List.of(id)).stream()
                .map(OpenApiKeyRow::getKeyId)
                .toList();
        return appView(stored, keyIds);
    }

    private Map<String, Object> appView(OpenAppRow app, List<String> keyIds) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", app.getId());
        m.put("name", app.getName());
        m.put("ownerMerchantId", app.getOwnerMerchantId());
        m.put("region", app.getRegion());
        m.put("status", app.getStatus());
        m.put("createdAt", app.getCreatedAt());
        m.put("keyIds", keyIds);
        return m;
    }

    private String randomHex(int numBytes) {
        byte[] buf = new byte[numBytes];
        RANDOM.nextBytes(buf);
        return HexFormat.of().formatHex(buf);
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
