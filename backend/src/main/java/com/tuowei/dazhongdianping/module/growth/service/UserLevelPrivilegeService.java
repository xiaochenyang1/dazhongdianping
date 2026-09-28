package com.tuowei.dazhongdianping.module.growth.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.growth.mapper.GrowthConfigMapper;
import com.tuowei.dazhongdianping.module.growth.model.LevelConfigRow;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class UserLevelPrivilegeService {

    private static final TypeReference<Map<String, Object>> PRIVILEGE_TYPE = new TypeReference<>() {
    };

    private final AuthCommandMapper authCommandMapper;
    private final GrowthConfigMapper growthConfigMapper;
    private final ObjectMapper objectMapper;

    public UserLevelPrivilegeService(
            AuthCommandMapper authCommandMapper,
            GrowthConfigMapper growthConfigMapper,
            ObjectMapper objectMapper) {
        this.authCommandMapper = authCommandMapper;
        this.growthConfigMapper = growthConfigMapper;
        this.objectMapper = objectMapper;
    }

    public Map<String, Object> current() {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        AppUserRow user = authCommandMapper.selectUserById(session.userId());
        if (user == null || user.getStatus() == null || user.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        int level = user.getLevel() == null ? 1 : user.getLevel();
        LevelConfigRow config = growthConfigMapper.selectLevel(level);
        if (config == null) {
            throw new IllegalArgumentException("等级配置不存在");
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("level", level);
        body.put("levelName", config.getLevelName());
        body.put("growthValue", user.getGrowthValue() == null ? 0 : user.getGrowthValue());
        body.put("privileges", parsePrivileges(config.getPrivilegeJson()));
        return body;
    }

    private Map<String, Object> parsePrivileges(String privilegeJson) {
        String json = privilegeJson == null || privilegeJson.isBlank() ? "{}" : privilegeJson;
        try {
            Map<String, Object> parsed = objectMapper.readValue(json, PRIVILEGE_TYPE);
            return parsed == null ? Map.of() : parsed;
        } catch (Exception exception) {
            throw new IllegalArgumentException("等级权益配置无效");
        }
    }
}
