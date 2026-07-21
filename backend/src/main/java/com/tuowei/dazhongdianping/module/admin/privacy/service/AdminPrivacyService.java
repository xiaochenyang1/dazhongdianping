package com.tuowei.dazhongdianping.module.admin.privacy.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.privacy.mapper.AdminPrivacyMapper;
import com.tuowei.dazhongdianping.module.admin.privacy.model.AdminPrivacyTaskQuery;
import com.tuowei.dazhongdianping.module.admin.privacy.model.AdminPrivacyTaskRow;
import com.tuowei.dazhongdianping.module.admin.privacy.model.response.AdminPrivacyTaskResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class AdminPrivacyService {

    private static final TypeReference<List<String>> STRING_LIST_TYPE = new TypeReference<>() {
    };
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminPrivacyMapper mapper;
    private final ObjectMapper objectMapper;

    public AdminPrivacyService(AdminPrivacyMapper mapper, ObjectMapper objectMapper) {
        this.mapper = mapper;
        this.objectMapper = objectMapper;
    }

    public PageResult<AdminPrivacyTaskResponse> listTasks(AdminPrivacyTaskQuery query) {
        query.normalize();
        long total = mapper.countPrivacyTasks(query);
        List<AdminPrivacyTaskResponse> list = mapper.selectPrivacyTasks(query).stream()
                .map(this::toResponse)
                .toList();
        return new PageResult<>(list, total, query.getPage(), query.getPageSize(), query.getOffset() + list.size() < total);
    }

    private AdminPrivacyTaskResponse toResponse(AdminPrivacyTaskRow row) {
        return new AdminPrivacyTaskResponse(
                row.getId(),
                row.getTaskType(),
                taskTypeText(row.getTaskType()),
                row.getUserId(),
                safeText(row.getUserNickname()),
                safeText(row.getAccount()),
                row.getStatus(),
                statusText(row.getTaskType(), row.getStatus()),
                readScopes(row.getScopeJson()),
                safeText(row.getFormat()),
                safeText(row.getFileName()),
                safeText(row.getFailReason()),
                safeText(row.getVerifyType()),
                safeText(row.getReason()),
                formatDateTime(row.getExpireAt()),
                formatDateTime(row.getCoolingOffExpireAt()),
                formatDateTime(row.getCompletedAt()),
                formatDateTime(row.getCancelledAt()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private List<String> readScopes(String scopeJson) {
        if (!StringUtils.hasText(scopeJson)) {
            return List.of();
        }
        try {
            return objectMapper.readValue(scopeJson, STRING_LIST_TYPE);
        } catch (JsonProcessingException exception) {
            return List.of();
        }
    }

    private String taskTypeText(Integer taskType) {
        return switch (taskType == null ? 0 : taskType) {
            case 1 -> "数据导出";
            case 2 -> "账号删除";
            default -> "";
        };
    }

    private String statusText(Integer taskType, Integer status) {
        if (status == null) {
            return "";
        }
        if (taskType != null && taskType == 2) {
            return switch (status) {
                case 0 -> "待确认";
                case 1 -> "冷静期中";
                case 2 -> "处理中";
                case 3 -> "已完成";
                case 4 -> "已取消";
                case 5 -> "已驳回";
                default -> "";
            };
        }
        return switch (status) {
            case 0 -> "待处理";
            case 1 -> "处理中";
            case 2 -> "可下载";
            case 3 -> "已过期";
            case 4 -> "失败";
            case 5 -> "已取消";
            default -> "";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }
}
