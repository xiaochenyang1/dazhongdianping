package com.tuowei.dazhongdianping.module.topic.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.topic.mapper.TopicMapper;
import com.tuowei.dazhongdianping.module.topic.model.TopicRow;
import com.tuowei.dazhongdianping.module.topic.model.response.TopicFollowResponse;
import com.tuowei.dazhongdianping.module.topic.model.response.TopicResponse;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class TopicService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final TopicMapper mapper;
    private final TopicHotRankingService hotRankingService;

    public TopicService(TopicMapper mapper, TopicHotRankingService hotRankingService) {
        this.mapper = mapper;
        this.hotRankingService = hotRankingService;
    }

    public PageResult<TopicResponse> list(String sort, Integer page, Integer pageSize) {
        String normalizedSort = normalizeSort(sort);
        PageWindow window = pageWindow(page, pageSize);
        String region = region();
        if ("hot".equals(normalizedSort)) hotRankingService.ensureRegionSnapshot(region);
        long total = mapper.countPublicTopics(region, normalizedSort);
        List<TopicResponse> items = mapper.listPublicTopics(region, optionalUserId(), normalizedSort,
                        window.size(), window.offset())
                .stream().map(this::toResponse).toList();
        return page(items, total, window);
    }

    public PageResult<TopicResponse> hot(Integer page, Integer pageSize) {
        return list("hot", page, pageSize);
    }

    public PageResult<TopicResponse> following(Integer page, Integer pageSize) {
        long userId = currentUserId();
        PageWindow window = pageWindow(page, pageSize);
        long total = mapper.countFollowingTopics(region(), userId);
        List<TopicResponse> items = mapper.listFollowingTopics(region(), userId, window.size(), window.offset())
                .stream().map(this::toResponse).toList();
        return page(items, total, window);
    }

    public TopicResponse detail(Long id) {
        return toResponse(requireAvailable(id));
    }

    public TopicRow requireAvailable(Long id) {
        TopicRow row = mapper.findAvailable(id, region(), optionalUserId());
        if (row == null) throw new NotFoundException("话题不存在");
        return row;
    }

    @Transactional
    public TopicFollowResponse follow(Long id) {
        requireAvailable(id);
        long userId = currentUserId();
        if (mapper.countFollow(id, userId) == 0) {
            try {
                mapper.insertFollow(id, userId);
            } catch (DuplicateKeyException ignored) {
                // 唯一键保证并发关注幂等。
            }
        }
        mapper.refreshFollowerCount(id);
        return new TopicFollowResponse(id, true, mapper.currentFollowerCount(id));
    }

    @Transactional
    public TopicFollowResponse unfollow(Long id) {
        requireAvailable(id);
        mapper.deleteFollow(id, currentUserId());
        mapper.refreshFollowerCount(id);
        return new TopicFollowResponse(id, false, mapper.currentFollowerCount(id));
    }

    public List<Long> resolveTopicIdsForPost(List<String> rawNames) {
        LinkedHashSet<String> names = new LinkedHashSet<>();
        if (rawNames != null) {
            for (String rawName : rawNames) {
                if (StringUtils.hasText(rawName)) names.add(rawName.trim());
            }
        }
        return names.stream().limit(5).map(this::resolveOrCreateTopicId).toList();
    }

    public List<Long> topicIdsForPost(Long postId) {
        return mapper.selectPostTopicIds(postId);
    }

    public void refreshPostCountsByPostId(Long postId) {
        refreshPostCounts(mapper.selectPostTopicIds(postId));
    }

    public void touchTopicsByPostId(Long postId) {
        mapper.touchTopicsByPostId(postId);
    }

    public void refreshPostCounts(Collection<Long> topicIds) {
        Set<Long> unique = new LinkedHashSet<>(topicIds == null ? List.of() : topicIds);
        unique.remove(null);
        if (!unique.isEmpty()) mapper.refreshPostCounts(new ArrayList<>(unique));
    }

    private Long resolveOrCreateTopicId(String name) {
        TopicRow existing = mapper.selectByNameAnyStatus(region(), name);
        if (existing != null) return resolveFinalTopic(existing).getId();

        TopicRow created = new TopicRow();
        created.setRegion(region());
        created.setName(name);
        try {
            mapper.insertTopic(created);
            return created.getId();
        } catch (DuplicateKeyException exception) {
            TopicRow concurrent = mapper.selectByNameAnyStatus(region(), name);
            if (concurrent == null) throw exception;
            return resolveFinalTopic(concurrent).getId();
        }
    }

    private TopicRow resolveFinalTopic(TopicRow row) {
        Set<Long> visited = new LinkedHashSet<>();
        TopicRow current = row;
        for (int depth = 0; depth < 16; depth++) {
            if (current == null || current.getId() == null || !visited.add(current.getId())) {
                throw new IllegalArgumentException("话题不可用");
            }
            if (current.getMergedToId() == null) {
                if (Integer.valueOf(1).equals(current.getStatus())) return current;
                throw new IllegalArgumentException("话题不可用");
            }
            current = mapper.selectByIdAnyStatus(current.getMergedToId(), region());
        }
        throw new IllegalArgumentException("话题不可用");
    }

    private TopicResponse toResponse(TopicRow row) {
        return new TopicResponse(
                row.getId(), row.getRegion(), row.getName(), value(row.getPostCount()), value(row.getFollowerCount()),
                Boolean.TRUE.equals(row.getRecommended()), value(row.getPinnedSort()), row.isFollowedByCurrentUser(),
                longValue(row.getHotScore()), value(row.getPostCount7d()), value(row.getLikeCount7d()),
                value(row.getCommentCount7d()), row.getCalculatedAt() == null ? "" : row.getCalculatedAt().format(FORMATTER)
        );
    }

    private String normalizeSort(String sort) {
        String value = StringUtils.hasText(sort) ? sort.trim().toLowerCase() : "latest";
        if (!List.of("recommended", "hot", "latest").contains(value)) {
            throw new IllegalArgumentException("sort 仅支持 recommended、hot 或 latest");
        }
        return value;
    }

    private Long optionalUserId() {
        UserSession session = UserSessionContext.get();
        return session == null ? null : session.userId();
    }

    private long currentUserId() {
        Long userId = optionalUserId();
        if (userId == null) throw new UnauthorizedException("用户登录状态不存在");
        return userId;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private PageWindow pageWindow(Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 20 : Math.min(50, Math.max(1, pageSize));
        return new PageWindow(currentPage, size, (currentPage - 1) * size);
    }

    private PageResult<TopicResponse> page(List<TopicResponse> items, long total, PageWindow window) {
        return new PageResult<>(items, total, window.page(), window.size(), window.offset() + items.size() < total);
    }

    private int value(Integer value) {
        return value == null ? 0 : value;
    }

    private long longValue(Long value) {
        return value == null ? 0L : value;
    }

    private record PageWindow(int page, int size, int offset) {}
}
