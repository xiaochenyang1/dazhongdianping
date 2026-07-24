package com.tuowei.dazhongdianping.module.activity.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.activity.mapper.PublicActivityMapper;
import com.tuowei.dazhongdianping.module.activity.model.PublicActivityItemRow;
import com.tuowei.dazhongdianping.module.activity.model.PublicActivityRow;
import com.tuowei.dazhongdianping.module.activity.model.response.PublicActivityDetailResponse;
import com.tuowei.dazhongdianping.module.activity.model.response.PublicActivityItemResponse;
import com.tuowei.dazhongdianping.module.activity.model.response.PublicActivitySummaryResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class PublicActivityService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final int DEFAULT_LIMIT = 12;
    private static final int MAX_LIMIT = 50;

    private final PublicActivityMapper publicActivityMapper;
    private final ObjectMapper objectMapper;

    public PublicActivityService(PublicActivityMapper publicActivityMapper, ObjectMapper objectMapper) {
        this.publicActivityMapper = publicActivityMapper;
        this.objectMapper = objectMapper;
    }

    public List<PublicActivitySummaryResponse> list(Region region, Long cityId, Integer channel, Integer limit) {
        Long normalizedCityId = cityId == null || cityId <= 0 ? null : cityId;
        Integer normalizedChannel = channel == null || channel <= 0 ? null : channel;
        int normalizedLimit = normalizeLimit(limit);
        return publicActivityMapper.selectOnlineActivities(
                        region.name(), normalizedCityId, normalizedChannel, normalizedLimit)
                .stream()
                .map(this::toSummary)
                .toList();
    }

    public PublicActivityDetailResponse detail(Region region, Long activityId) {
        PublicActivityRow row = publicActivityMapper.selectOnlineActivity(activityId, region.name());
        if (row == null) {
            throw new NotFoundException("活动不存在或未上线");
        }
        List<PublicActivityItemResponse> items = publicActivityMapper
                .selectEnabledItems(activityId, region.name())
                .stream()
                .map(this::toItem)
                .toList();
        return toDetail(row, items);
    }

    private PublicActivitySummaryResponse toSummary(PublicActivityRow row) {
        return new PublicActivitySummaryResponse(
                row.getId(),
                row.getName(),
                row.getCode(),
                row.getRegion(),
                cityId(row),
                cityName(row),
                value(row.getChannel()),
                channelText(row.getChannel()),
                value(row.getType()),
                typeText(row.getType()),
                text(row.getCover()),
                text(row.getLandingUrl()),
                format(row.getStartAt()),
                format(row.getEndAt()),
                value(row.getItemCount())
        );
    }

    private PublicActivityDetailResponse toDetail(PublicActivityRow row, List<PublicActivityItemResponse> items) {
        return new PublicActivityDetailResponse(
                row.getId(),
                row.getName(),
                row.getCode(),
                row.getRegion(),
                cityId(row),
                cityName(row),
                value(row.getChannel()),
                channelText(row.getChannel()),
                value(row.getType()),
                typeText(row.getType()),
                text(row.getCover()),
                text(row.getLandingUrl()),
                parseJson(row.getRuleJson()),
                format(row.getStartAt()),
                format(row.getEndAt()),
                items
        );
    }

    private PublicActivityItemResponse toItem(PublicActivityItemRow row) {
        JsonNode extra = parseJson(row.getExtraJson());
        return new PublicActivityItemResponse(
                row.getId(),
                row.getActivityId(),
                value(row.getTargetType()),
                targetTypeText(row.getTargetType()),
                row.getTargetId() == null ? 0L : row.getTargetId(),
                text(row.getTargetName()),
                text(row.getTitle()),
                text(row.getSubtitle()),
                text(row.getImage()),
                value(row.getSort()),
                extra,
                resolveLinkUrl(row.getTargetType(), row.getTargetId(), extra)
        );
    }

    private String resolveLinkUrl(Integer targetType, Long targetId, JsonNode extra) {
        long id = targetId == null ? 0L : targetId;
        return switch (targetType == null ? 0 : targetType) {
            case 1 -> "/shops/" + id;
            case 2 -> "/deals/" + id;
            case 3 -> "/community/posts/" + id;
            case 4 -> "/ranks/" + id;
            case 5 -> "/topics/" + id;
            case 6 -> text(extra.path("url").asText(""));
            default -> "";
        };
    }

    private int normalizeLimit(Integer limit) {
        if (limit == null || limit <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
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

    private String typeText(Integer value) {
        return switch (value == null ? 0 : value) {
            case 1 -> "专题活动";
            case 2 -> "节日活动";
            case 3 -> "新客活动";
            case 4 -> "商户扶持";
            case 5 -> "内容话题";
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

    private Long cityId(PublicActivityRow row) {
        return row.getCityId() == null ? 0L : row.getCityId();
    }

    private String cityName(PublicActivityRow row) {
        if (row.getCityId() == null || row.getCityId() == 0) {
            return "全区域";
        }
        return text(row.getCityName());
    }

    private String format(LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }

    private int value(Integer value) {
        return value == null ? 0 : value;
    }

    private String text(String value) {
        return value == null ? "" : value.trim();
    }
}
