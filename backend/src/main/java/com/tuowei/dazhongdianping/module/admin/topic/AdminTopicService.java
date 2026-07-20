package com.tuowei.dazhongdianping.module.admin.topic;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicRecommendationRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicStatusRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.TopicUpdateRequest;
import com.tuowei.dazhongdianping.module.admin.topic.model.response.AdminTopicResponse;
import com.tuowei.dazhongdianping.module.topic.mapper.TopicMapper;
import com.tuowei.dazhongdianping.module.topic.model.TopicRow;
import com.tuowei.dazhongdianping.module.topic.service.TopicHotRankingService;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminTopicService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final TopicMapper mapper;
    private final TopicHotRankingService hotRankingService;

    public AdminTopicService(TopicMapper mapper, TopicHotRankingService hotRankingService) {
        this.mapper = mapper;
        this.hotRankingService = hotRankingService;
    }

    public PageResult<AdminTopicResponse> list(Integer status, Boolean recommended, String keyword,
                                                Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 20 : Math.min(50, Math.max(1, pageSize));
        int offset = (currentPage - 1) * size;
        String key = keyword == null ? "" : keyword.trim();
        long total = mapper.countAdminTopics(region(), status, recommended, key);
        List<AdminTopicResponse> items = mapper.listAdminTopics(region(), status, recommended, key, size, offset)
                .stream().map(this::response).toList();
        return new PageResult<>(items, total, currentPage, size, offset + items.size() < total);
    }

    @Transactional
    public AdminTopicResponse update(Long id, TopicUpdateRequest request) {
        require(id);
        String name = request.name().trim();
        if (mapper.countTopicNameConflict(region(), name, id) > 0) {
            throw new ConflictException("当前区域已存在同名话题");
        }
        if (mapper.updateTopicName(id, region(), name) == 0) throw new NotFoundException("话题不存在");
        return response(require(id));
    }

    @Transactional
    public AdminTopicResponse recommendation(Long id, TopicRecommendationRequest request) {
        require(id);
        mapper.updateTopicRecommendation(id, region(), request.recommended(), request.pinnedSort());
        hotRankingService.recalculateDirtyRegion(region());
        return response(require(id));
    }

    @Transactional
    public AdminTopicResponse status(Long id, TopicStatusRequest request) {
        require(id);
        mapper.updateTopicStatus(id, region(), request.status());
        if (request.status() == 2) mapper.deleteHotSnapshot(id);
        else hotRankingService.recalculateDirtyRegion(region());
        return response(require(id));
    }

    @Transactional
    public AdminTopicResponse merge(Long sourceId, Long targetId) {
        if (sourceId.equals(targetId)) throw new IllegalArgumentException("不能合并话题自身");
        TopicRow source = mapper.findAdminTopicForUpdate(sourceId, region());
        if (source == null) throw new NotFoundException("话题不存在");
        TopicRow target = mapper.findAnyTopicForUpdate(targetId);
        if (target == null) throw new IllegalArgumentException("目标话题不存在");
        if (!region().equals(target.getRegion())) throw new IllegalArgumentException("不能跨区域合并话题");
        if (source.getMergedToId() != null || target.getMergedToId() != null) {
            throw new IllegalArgumentException("已合并话题不能再次作为合并对象");
        }
        if (!Integer.valueOf(1).equals(target.getStatus())) throw new IllegalArgumentException("目标话题不可用");

        for (Long postId : mapper.selectPostIdsByTopic(sourceId)) {
            if (mapper.countPostTopic(targetId, postId) > 0) mapper.deletePostTopic(sourceId, postId);
            else mapper.movePostTopic(sourceId, targetId, postId);
        }
        for (Long userId : mapper.selectFollowerUserIds(sourceId)) {
            if (mapper.countTopicFollow(targetId, userId) > 0) mapper.deleteTopicFollow(sourceId, userId);
            else mapper.moveTopicFollow(sourceId, targetId, userId);
        }

        mapper.markTopicMerged(sourceId, region(), targetId);
        mapper.refreshPostCounts(List.of(targetId));
        mapper.refreshFollowerCount(targetId);
        mapper.deleteHotSnapshot(sourceId);
        hotRankingService.recalculateDirtyRegion(region());
        return response(require(targetId));
    }

    @Transactional
    public Map<String, String> recalculateHot() {
        hotRankingService.recalculateRegion(region());
        return Map.of("region", region(), "calculatedAt", LocalDateTime.now().format(FORMATTER));
    }

    private TopicRow require(Long id) {
        TopicRow row = mapper.findAdminTopic(id, region());
        if (row == null) throw new NotFoundException("话题不存在");
        return row;
    }

    private AdminTopicResponse response(TopicRow row) {
        return new AdminTopicResponse(
                row.getId(), row.getRegion(), row.getName(), value(row.getPostCount()), value(row.getFollowerCount()),
                Boolean.TRUE.equals(row.getRecommended()), value(row.getPinnedSort()), value(row.getStatus()),
                row.getMergedToId(), longValue(row.getHotScore()), value(row.getPostCount7d()),
                value(row.getLikeCount7d()), value(row.getCommentCount7d()),
                row.getCalculatedAt() == null ? "" : row.getCalculatedAt().format(FORMATTER)
        );
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private int value(Integer value) {
        return value == null ? 0 : value;
    }

    private long longValue(Long value) {
        return value == null ? 0L : value;
    }
}
