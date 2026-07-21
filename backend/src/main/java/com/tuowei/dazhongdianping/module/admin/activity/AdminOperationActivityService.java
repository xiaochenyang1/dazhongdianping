package com.tuowei.dazhongdianping.module.admin.activity;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.activity.mapper.AdminOperationActivityMapper;
import com.tuowei.dazhongdianping.module.admin.activity.model.AdminOperationActivityItemRow;
import com.tuowei.dazhongdianping.module.admin.activity.model.AdminOperationActivityRow;
import com.tuowei.dazhongdianping.module.admin.activity.model.request.AdminOperationActivityItemSaveRequest;
import com.tuowei.dazhongdianping.module.admin.activity.model.request.AdminOperationActivitySaveRequest;
import com.tuowei.dazhongdianping.module.admin.activity.model.response.AdminOperationActivityItemResponse;
import com.tuowei.dazhongdianping.module.admin.activity.model.response.AdminOperationActivityResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminOperationActivityService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminOperationActivityMapper mapper;
    private final AdminAuditLogService auditLogService;
    private final ObjectMapper objectMapper;

    public AdminOperationActivityService(AdminOperationActivityMapper mapper,
                                         AdminAuditLogService auditLogService,
                                         ObjectMapper objectMapper) {
        this.mapper = mapper;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
    }

    public List<AdminOperationActivityResponse> list(Long cityId, Integer status) {
        Long normalizedCityId = cityId == null || cityId <= 0 ? null : cityId;
        return mapper.selectActivities(region(), normalizedCityId, status).stream()
                .map(this::toActivityResponse)
                .toList();
    }

    @Transactional
    public AdminOperationActivityResponse create(AdminOperationActivitySaveRequest request, String requestIp) {
        AdminSession admin = currentAdmin();
        Long cityId = normalizeCityId(request.cityId());
        ensureCityAvailable(cityId);
        validateActivitySchedule(request.startAt(), request.endAt());

        String code = normalizeCode(request.code());
        requireUniqueCode(code, null);

        AdminOperationActivityRow row = new AdminOperationActivityRow();
        row.setName(request.name().trim());
        row.setCode(code);
        row.setRegion(region());
        row.setCityId(cityId);
        row.setChannel(request.channel());
        row.setType(request.type());
        row.setStatus(0);
        row.setCover(request.cover().trim());
        row.setLandingUrl(request.landingUrl().trim());
        row.setRuleJson(toJsonText(request.rule(), "rule"));
        row.setStartAt(request.startAt());
        row.setEndAt(request.endAt());
        row.setCreatedBy(admin.adminId());
        row.setUpdatedBy(admin.adminId());
        mapper.insertActivity(row);

        AdminOperationActivityResponse response = toActivityResponse(requireActivity(row.getId()));
        recordActivity("admin.activity_create", "activity:" + response.id(), response, requestIp);
        return response;
    }

    @Transactional
    public AdminOperationActivityResponse update(Long id,
                                                 AdminOperationActivitySaveRequest request,
                                                 String requestIp) {
        AdminSession admin = currentAdmin();
        AdminOperationActivityRow row = requireActivity(id);
        Long cityId = normalizeCityId(request.cityId());
        ensureCityAvailable(cityId);
        validateActivitySchedule(request.startAt(), request.endAt());

        String code = normalizeCode(request.code());
        requireUniqueCode(code, id);

        row.setName(request.name().trim());
        row.setCode(code);
        row.setCityId(cityId);
        row.setChannel(request.channel());
        row.setType(request.type());
        row.setCover(request.cover().trim());
        row.setLandingUrl(request.landingUrl().trim());
        row.setRuleJson(toJsonText(request.rule(), "rule"));
        row.setStartAt(request.startAt());
        row.setEndAt(request.endAt());
        row.setUpdatedBy(admin.adminId());
        if (mapper.updateActivity(row) != 1) {
            throw new NotFoundException("活动不存在");
        }

        AdminOperationActivityResponse response = toActivityResponse(requireActivity(id));
        recordActivity("admin.activity_update", "activity:" + id, response, requestIp);
        return response;
    }

    @Transactional
    public AdminOperationActivityResponse updateStatus(Long id, Integer status, String requestIp) {
        AdminSession admin = currentAdmin();
        AdminOperationActivityRow existing = requireActivity(id);
        if (mapper.updateActivityStatus(id, region(), status, admin.adminId()) != 1) {
            throw new NotFoundException("活动不存在");
        }
        AdminOperationActivityResponse response = toActivityResponse(requireActivity(id));
        String detail = String.format(
                "code=%s, status=%s -> %s",
                existing.getCode(),
                activityStatusText(existing.getStatus()),
                activityStatusText(status)
        );
        auditLogService.record(admin.adminId(), "admin.activity_status", "activity:" + id, detail, requestIp);
        return response;
    }

    @Transactional
    public void delete(Long id, String requestIp) {
        AdminSession admin = currentAdmin();
        AdminOperationActivityRow existing = requireActivity(id);
        mapper.deleteItemsByActivity(id);
        if (mapper.deleteActivity(id, region()) != 1) {
            throw new NotFoundException("活动不存在");
        }
        auditLogService.record(
                admin.adminId(),
                "admin.activity_delete",
                "activity:" + id,
                "code=" + existing.getCode() + ", name=" + existing.getName(),
                requestIp
        );
    }

    public List<AdminOperationActivityItemResponse> listItems(Long activityId) {
        requireActivity(activityId);
        return mapper.selectItems(activityId, region()).stream()
                .map(this::toItemResponse)
                .toList();
    }

    @Transactional
    public AdminOperationActivityItemResponse createItem(Long activityId,
                                                         AdminOperationActivityItemSaveRequest request,
                                                         String requestIp) {
        requireActivity(activityId);
        validateItemRequest(activityId, request.targetType(), request.targetId(), request.extra(), null);

        AdminOperationActivityItemRow row = new AdminOperationActivityItemRow();
        row.setActivityId(activityId);
        row.setTargetType(request.targetType());
        row.setTargetId(normalizeTargetId(request.targetType(), request.targetId()));
        row.setTitle(request.title().trim());
        row.setSubtitle(text(request.subtitle()));
        row.setImage(request.image().trim());
        row.setSort(request.sort());
        row.setExtraJson(toJsonText(request.extra(), "extra"));
        row.setStatus(1);
        mapper.insertItem(row);

        AdminOperationActivityItemResponse response = toItemResponse(requireItem(activityId, row.getId()));
        recordItem("admin.activity_item_create", "activity_item:" + response.id(), response, requestIp);
        return response;
    }

    @Transactional
    public AdminOperationActivityItemResponse updateItem(Long activityId,
                                                         Long itemId,
                                                         AdminOperationActivityItemSaveRequest request,
                                                         String requestIp) {
        requireActivity(activityId);
        requireItem(activityId, itemId);
        validateItemRequest(activityId, request.targetType(), request.targetId(), request.extra(), itemId);

        AdminOperationActivityItemRow row = new AdminOperationActivityItemRow();
        row.setId(itemId);
        row.setActivityId(activityId);
        row.setTargetType(request.targetType());
        row.setTargetId(normalizeTargetId(request.targetType(), request.targetId()));
        row.setTitle(request.title().trim());
        row.setSubtitle(text(request.subtitle()));
        row.setImage(request.image().trim());
        row.setSort(request.sort());
        row.setExtraJson(toJsonText(request.extra(), "extra"));
        if (mapper.updateItem(row) != 1) {
            throw new NotFoundException("活动资源项不存在");
        }

        AdminOperationActivityItemResponse response = toItemResponse(requireItem(activityId, itemId));
        recordItem("admin.activity_item_update", "activity_item:" + itemId, response, requestIp);
        return response;
    }

    @Transactional
    public AdminOperationActivityItemResponse updateItemStatus(Long activityId,
                                                               Long itemId,
                                                               Integer status,
                                                               String requestIp) {
        AdminSession admin = currentAdmin();
        AdminOperationActivityItemRow existing = requireItem(activityId, itemId);
        if (mapper.updateItemStatus(activityId, itemId, region(), status) != 1) {
            throw new NotFoundException("活动资源项不存在");
        }

        AdminOperationActivityItemResponse response = toItemResponse(requireItem(activityId, itemId));
        String detail = String.format(
                "targetType=%s, targetId=%d, status=%s -> %s",
                targetTypeText(existing.getTargetType()),
                value(existing.getTargetId()),
                itemStatusText(existing.getStatus()),
                itemStatusText(status)
        );
        auditLogService.record(admin.adminId(), "admin.activity_item_status", "activity_item:" + itemId, detail, requestIp);
        return response;
    }

    @Transactional
    public void deleteItem(Long activityId, Long itemId, String requestIp) {
        AdminSession admin = currentAdmin();
        AdminOperationActivityItemRow existing = requireItem(activityId, itemId);
        if (mapper.deleteItem(activityId, itemId, region()) != 1) {
            throw new NotFoundException("活动资源项不存在");
        }
        auditLogService.record(
                admin.adminId(),
                "admin.activity_item_delete",
                "activity_item:" + itemId,
                "targetType=" + targetTypeText(existing.getTargetType()) + ", targetId=" + value(existing.getTargetId()),
                requestIp
        );
    }

    private AdminOperationActivityRow requireActivity(Long id) {
        AdminOperationActivityRow row = mapper.selectActivity(id, region());
        if (row == null) {
            throw new NotFoundException("活动不存在");
        }
        return row;
    }

    private AdminOperationActivityItemRow requireItem(Long activityId, Long itemId) {
        requireActivity(activityId);
        AdminOperationActivityItemRow row = mapper.selectItem(activityId, itemId, region());
        if (row == null) {
            throw new NotFoundException("活动资源项不存在");
        }
        return row;
    }

    private void validateActivitySchedule(LocalDateTime startAt, LocalDateTime endAt) {
        if (startAt != null && endAt != null && !endAt.isAfter(startAt)) {
            throw new IllegalArgumentException("endAt 必须晚于 startAt");
        }
    }

    private void validateItemRequest(Long activityId,
                                     Integer targetType,
                                     Long targetId,
                                     JsonNode extra,
                                     Long excludeId) {
        requireUniqueItem(activityId, targetType, normalizeTargetId(targetType, targetId), excludeId);
        if (extra != null && !extra.isNull() && !extra.isObject()) {
            throw new IllegalArgumentException("extra 必须是 JSON 对象");
        }
        if (targetType == null || targetType < 1 || targetType > 6) {
            throw new IllegalArgumentException("targetType 仅支持 1 到 6");
        }
        if (targetType == 6) {
            if (normalizeTargetId(targetType, targetId) != 0L) {
                throw new IllegalArgumentException("外链资源 targetId 必须为 0");
            }
            if (objectText(extra, "url").isBlank()) {
                throw new IllegalArgumentException("外链资源 extra.url 不能为空");
            }
            return;
        }

        Long normalizedTargetId = normalizeTargetId(targetType, targetId);
        int count = switch (targetType) {
            case 1 -> value(mapper.countAvailableShop(normalizedTargetId, region()));
            case 2 -> value(mapper.countAvailableDeal(normalizedTargetId, region()));
            case 3 -> value(mapper.countAvailablePost(normalizedTargetId, region()));
            case 4 -> value(mapper.countAvailableRank(normalizedTargetId, region()));
            case 5 -> value(mapper.countAvailableTopic(normalizedTargetId, region()));
            default -> 0;
        };
        if (count == 0) {
            throw new IllegalArgumentException(targetTypeText(targetType) + "不存在或不可用");
        }
    }

    private void requireUniqueCode(String code, Long excludeId) {
        Integer count = mapper.countActivityCodeConflict(code, excludeId);
        if (count != null && count > 0) {
            throw new ConflictException("活动编码已存在");
        }
    }

    private void requireUniqueItem(Long activityId, Integer targetType, Long targetId, Long excludeId) {
        Integer count = mapper.countActivityItemConflict(activityId, targetType, targetId, excludeId);
        if (count != null && count > 0) {
            throw new ConflictException("当前活动已存在相同资源项");
        }
    }

    private void ensureCityAvailable(Long cityId) {
        if (cityId == null || cityId <= 0) {
            return;
        }
        Integer count = mapper.countActiveCity(cityId, region());
        if (count == null || count == 0) {
            throw new ConflictException("当前区域城市不存在或已停用");
        }
    }

    private AdminOperationActivityResponse toActivityResponse(AdminOperationActivityRow row) {
        return new AdminOperationActivityResponse(
                row.getId(),
                row.getRegion(),
                row.getCityId() == null ? 0L : row.getCityId(),
                row.getCityId() == null || row.getCityId() == 0 ? "" : text(row.getCityName()),
                row.getName(),
                row.getCode(),
                value(row.getChannel()),
                channelText(row.getChannel()),
                value(row.getType()),
                activityTypeText(row.getType()),
                value(row.getStatus()),
                activityStatusText(row.getStatus()),
                row.getCover(),
                row.getLandingUrl(),
                parseJson(row.getRuleJson()),
                format(row.getStartAt()),
                format(row.getEndAt()),
                value(row.getItemCount())
        );
    }

    private AdminOperationActivityItemResponse toItemResponse(AdminOperationActivityItemRow row) {
        return new AdminOperationActivityItemResponse(
                row.getId(),
                row.getActivityId(),
                value(row.getTargetType()),
                targetTypeText(row.getTargetType()),
                row.getTargetId() == null ? 0L : row.getTargetId(),
                text(row.getTargetName()),
                row.getTitle(),
                text(row.getSubtitle()),
                row.getImage(),
                value(row.getSort()),
                parseJson(row.getExtraJson()),
                value(row.getStatus()),
                itemStatusText(row.getStatus())
        );
    }

    private void recordActivity(String action,
                                String target,
                                AdminOperationActivityResponse response,
                                String requestIp) {
        String detail = String.format(
                "region=%s, cityId=%d, code=%s, status=%s, channel=%s, type=%s",
                response.region(),
                response.cityId(),
                response.code(),
                response.statusText(),
                response.channelText(),
                response.typeText()
        );
        auditLogService.record(currentAdmin().adminId(), action, target, detail, requestIp);
    }

    private void recordItem(String action,
                            String target,
                            AdminOperationActivityItemResponse response,
                            String requestIp) {
        String detail = String.format(
                "activityId=%d, targetType=%s, targetId=%d, status=%s, sort=%d",
                response.activityId(),
                response.targetTypeText(),
                response.targetId(),
                response.statusText(),
                response.sort()
        );
        auditLogService.record(currentAdmin().adminId(), action, target, detail, requestIp);
    }

    private JsonNode parseJson(String value) {
        if (value == null || value.isBlank()) {
            return objectMapper.createObjectNode();
        }
        try {
            return objectMapper.readTree(value);
        } catch (JsonProcessingException exception) {
            return objectMapper.createObjectNode();
        }
    }

    private String toJsonText(JsonNode value, String fieldName) {
        if (value == null || value.isNull()) {
            return "{}";
        }
        if (!value.isObject()) {
            throw new IllegalArgumentException(fieldName + " 必须是 JSON 对象");
        }
        try {
            String text = objectMapper.writeValueAsString(value);
            if (text.length() > 2000) {
                throw new IllegalArgumentException(fieldName + " 长度不能超过 2000 字");
            }
            return text;
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException(fieldName + " 解析失败");
        }
    }

    private String objectText(JsonNode node, String fieldName) {
        if (node == null || node.isNull()) {
            return "";
        }
        if (!node.isObject()) {
            throw new IllegalArgumentException("extra 必须是 JSON 对象");
        }
        return text(node.path(fieldName).asText(""));
    }

    private String normalizeCode(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private Long normalizeCityId(Long value) {
        return value == null || value <= 0 ? 0L : value;
    }

    private Long normalizeTargetId(Integer targetType, Long targetId) {
        if (targetType != null && targetType == 6) {
            return targetId == null ? 0L : targetId;
        }
        if (targetId == null || targetId < 1) {
            throw new IllegalArgumentException("targetId 最小为 1");
        }
        return targetId;
    }

    private String format(LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }

    private String channelText(Integer value) {
        return switch (value == null ? 0 : value) {
            case 1 -> "首页";
            case 2 -> "搜索";
            case 3 -> "频道";
            case 4 -> "活动页";
            case 5 -> "社区";
            default -> "";
        };
    }

    private String activityTypeText(Integer value) {
        return switch (value == null ? 0 : value) {
            case 1 -> "专题活动";
            case 2 -> "节日活动";
            case 3 -> "新客活动";
            case 4 -> "商户扶持";
            case 5 -> "内容话题";
            default -> "";
        };
    }

    private String activityStatusText(Integer value) {
        return switch (value == null ? -1 : value) {
            case 0 -> "草稿";
            case 1 -> "待上线";
            case 2 -> "上线中";
            case 3 -> "已下线";
            case 4 -> "已结束";
            default -> "";
        };
    }

    private String targetTypeText(Integer value) {
        return switch (value == null ? 0 : value) {
            case 1 -> "店铺";
            case 2 -> "团购";
            case 3 -> "帖子";
            case 4 -> "榜单";
            case 5 -> "话题";
            case 6 -> "外链";
            default -> "";
        };
    }

    private String itemStatusText(Integer value) {
        return switch (value == null ? 0 : value) {
            case 1 -> "启用";
            case 2 -> "停用";
            default -> "";
        };
    }

    private int value(Integer value) {
        return value == null ? 0 : value;
    }

    private long value(Long value) {
        return value == null ? 0L : value;
    }

    private String text(String value) {
        return value == null ? "" : value.trim();
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员未登录");
        }
        return session;
    }
}
