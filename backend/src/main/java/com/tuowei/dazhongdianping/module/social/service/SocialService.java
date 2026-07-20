package com.tuowei.dazhongdianping.module.social.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.social.mapper.SocialMapper;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.social.model.SocialUserRow;
import com.tuowei.dazhongdianping.module.social.model.response.FollowStatusResponse;
import com.tuowei.dazhongdianping.module.social.model.response.SocialUserResponse;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SocialService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final SocialMapper mapper;
    private final NotificationService notifications;
    public SocialService(SocialMapper mapper, NotificationService notifications) { this.mapper = mapper; this.notifications = notifications; }

    @Transactional
    public FollowStatusResponse follow(Long targetUserId) {
        Long currentUserId = currentUser().userId();
        if (currentUserId.equals(targetUserId)) throw new IllegalArgumentException("不能关注自己");
        requirePublicUser(targetUserId);
        if (mapper.countRelation(currentUserId, targetUserId) == 0) {
            boolean created = false;
            try { mapper.insertRelation(currentUserId, targetUserId); created = true; } catch (DuplicateKeyException ignored) { }
            if (created) notifications.create(targetUserId, currentUserId, "GLOBAL", "social.follow", "新增关注",
                    mapper.selectUserName(currentUserId) + " 关注了你", "/users/" + currentUserId);
        }
        return new FollowStatusResponse(targetUserId, true, mapper.countFollowers(targetUserId));
    }

    @Transactional
    public FollowStatusResponse unfollow(Long targetUserId) {
        Long currentUserId = currentUser().userId();
        requirePublicUser(targetUserId);
        mapper.deleteRelation(currentUserId, targetUserId);
        return new FollowStatusResponse(targetUserId, false, mapper.countFollowers(targetUserId));
    }

    public PageResult<SocialUserResponse> followers(Long userId, Integer page, Integer pageSize) {
        requirePublicUser(userId);
        return page(userId, page, pageSize, true);
    }

    public PageResult<SocialUserResponse> following(Long userId, Integer page, Integer pageSize) {
        requirePublicUser(userId);
        return page(userId, page, pageSize, false);
    }

    public long followerCount(Long userId) { return mapper.countFollowers(userId); }
    public long followingCount(Long userId) { return mapper.countFollowing(userId); }
    public boolean followedByCurrentUser(Long userId) {
        UserSession viewer = UserSessionContext.get();
        return viewer != null && !viewer.userId().equals(userId) && mapper.countRelation(viewer.userId(), userId) > 0;
    }

    private PageResult<SocialUserResponse> page(Long userId, Integer page, Integer pageSize, boolean followers) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 20 : Math.min(50, Math.max(1, pageSize));
        long total = followers ? mapper.countFollowers(userId) : mapper.countFollowing(userId);
        int offset = (currentPage - 1) * size;
        List<SocialUserRow> rows = followers ? mapper.selectFollowers(userId, size, offset) : mapper.selectFollowing(userId, size, offset);
        Long viewerId = UserSessionContext.get() == null ? null : UserSessionContext.get().userId();
        List<SocialUserResponse> list = rows.stream().map(row -> toResponse(row, viewerId)).toList();
        return new PageResult<>(list, total, currentPage, size, offset + list.size() < total);
    }

    private SocialUserResponse toResponse(SocialUserRow row, Long viewerId) {
        boolean followed = viewerId != null && !viewerId.equals(row.getId()) && mapper.countRelation(viewerId, row.getId()) > 0;
        return new SocialUserResponse(row.getId(), row.getNickname(), row.getAvatar(), row.getSignature(), row.getLevel(),
                row.getFollowerCount(), followed, row.getFollowedAt() == null ? "" : row.getFollowedAt().format(FORMATTER));
    }

    private void requirePublicUser(Long userId) {
        if (mapper.countAvailableUser(userId) == 0) throw new NotFoundException("用户不存在");
    }

    private UserSession currentUser() {
        UserSession session = UserSessionContext.get();
        if (session == null) throw new UnauthorizedException("用户登录状态不存在");
        return session;
    }
}
