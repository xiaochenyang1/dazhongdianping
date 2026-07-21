package com.tuowei.dazhongdianping.module.circle.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.circle.mapper.CircleMapper;
import com.tuowei.dazhongdianping.module.community.mapper.CommunityMapper;
import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.community.model.response.PostResponse;
import com.tuowei.dazhongdianping.module.circle.model.CircleMemberRow;
import com.tuowei.dazhongdianping.module.circle.model.CircleRow;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleMemberResponse;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleMembershipResponse;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleResponse;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.LinkedHashSet;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CircleService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final CircleMapper mapper;
    private final CommunityMapper communityMapper;
    public CircleService(CircleMapper mapper, CommunityMapper communityMapper) { this.mapper = mapper; this.communityMapper = communityMapper; }

    public PageResult<CircleResponse> list(Boolean joined, Integer page, Integer pageSize) {
        PageWindow window = pageWindow(page, pageSize);
        boolean joinedOnly = Boolean.TRUE.equals(joined);
        Long userId = optionalUserId();
        if (joinedOnly && userId == null) throw new UnauthorizedException("查看我的圈子需要登录");
        String region = RegionContext.getRegion().name();
        long total = mapper.countCircles(region, userId, joinedOnly);
        List<CircleResponse> items = mapper.listCircles(region, userId, joinedOnly, window.size(), window.offset())
                .stream().map(this::toResponse).toList();
        return new PageResult<>(items, total, window.page(), window.size(), window.offset() + items.size() < total);
    }

    public CircleResponse detail(Long id) { return toResponse(requireAvailable(id)); }

    public void requirePostingMembership(Long id, Long userId) {
        requireAvailable(id);
        if (mapper.countMembership(id, userId) == 0) throw new ConflictException("请先加入圈子再发帖");
    }

    public PageResult<PostResponse> posts(Long id, Integer page, Integer pageSize) {
        requireAvailable(id);
        PageWindow window = pageWindow(page, pageSize);
        String region = RegionContext.getRegion().name();
        long total = communityMapper.countCirclePosts(id, region);
        Long currentUserId = optionalUserId();
        List<PostRow> rows = communityMapper.selectCirclePosts(id, region, window.size(), window.offset());
        LinkedHashSet<Long> repostedPostIds = currentUserId == null || rows.isEmpty()
                ? new LinkedHashSet<>()
                : new LinkedHashSet<>(communityMapper.selectUserPostRepostIds(
                        rows.stream().map(PostRow::getId).toList(), currentUserId));
        List<PostResponse> items = rows.stream()
                .map(row -> new PostResponse(row.getId(), row.getUserId(), row.getCircleId(), row.getCircleName(),
                        row.getUserName(), row.getTitle(), row.getContent(), row.getContentType(), row.getShopId(), row.getDealId(),
                        row.getLikeCount(), row.getCommentCount(), row.getRepostCount(),
                        repostedPostIds.contains(row.getId()),
                        row.getAuditStatus(), "审核通过", row.getAuditRemark(), row.getStatus(),
                        communityMapper.selectPostImages(row.getId()), communityMapper.selectPostTopics(row.getId()),
                        row.getCreatedAt() == null ? "" : row.getCreatedAt().format(FORMATTER),
                        row.getUpdatedAt() == null ? "" : row.getUpdatedAt().format(FORMATTER))).toList();
        return new PageResult<>(items, total, window.page(), window.size(), window.offset() + items.size() < total);
    }

    public PageResult<CircleMemberResponse> members(Long id, Integer page, Integer pageSize) {
        requireAvailable(id);
        PageWindow window = pageWindow(page, pageSize);
        long total = mapper.countMembers(id);
        List<CircleMemberResponse> items = mapper.listMembers(id, window.size(), window.offset()).stream()
                .map(this::toMember).toList();
        return new PageResult<>(items, total, window.page(), window.size(), window.offset() + items.size() < total);
    }

    @Transactional
    public CircleMembershipResponse join(Long id) {
        requireAvailable(id);
        long userId = currentUserId();
        if (mapper.countMembership(id, userId) == 0) {
            boolean inserted = false;
            try { inserted = mapper.insertMembership(id, userId) > 0; } catch (DuplicateKeyException ignored) { }
            if (inserted) mapper.incrementMembers(id);
        }
        return new CircleMembershipResponse(id, true, mapper.currentMemberCount(id));
    }

    @Transactional
    public CircleMembershipResponse leave(Long id) {
        requireAvailable(id);
        long userId = currentUserId();
        if (mapper.deleteMembership(id, userId) > 0) mapper.decrementMembers(id);
        return new CircleMembershipResponse(id, false, mapper.currentMemberCount(id));
    }

    private CircleRow requireAvailable(Long id) {
        CircleRow row = mapper.findAvailable(id, RegionContext.getRegion().name(), optionalUserId());
        if (row == null) throw new NotFoundException("圈子不存在");
        return row;
    }
    private CircleResponse toResponse(CircleRow row) {
        return new CircleResponse(row.getId(), row.getRegion(), row.getName(), row.getDescription(), row.getCoverUrl(),
                value(row.getMemberCount()), value(row.getPostCount()), value(row.getSort()), value(row.getStatus()), row.isJoinedByCurrentUser());
    }
    private CircleMemberResponse toMember(CircleMemberRow row) {
        return new CircleMemberResponse(row.getId(), row.getNickname(), row.getAvatar(), row.getSignature(), value(row.getLevel()),
                row.getJoinedAt() == null ? "" : row.getJoinedAt().format(FORMATTER));
    }
    private Long optionalUserId() { UserSession session = UserSessionContext.get(); return session == null ? null : session.userId(); }
    private long currentUserId() { Long id = optionalUserId(); if (id == null) throw new UnauthorizedException("用户登录状态不存在"); return id; }
    private int value(Integer value) { return value == null ? 0 : value; }
    private PageWindow pageWindow(Integer page, Integer size) { int p = page == null ? 1 : Math.max(1, page); int s = size == null ? 20 : Math.min(50, Math.max(1, size)); return new PageWindow(p, s, (p - 1) * s); }
    private record PageWindow(int page, int size, int offset) {}
}
