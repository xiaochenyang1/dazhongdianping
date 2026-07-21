package com.tuowei.dazhongdianping.module.community.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.community.mapper.CommunityMapper;
import com.tuowei.dazhongdianping.module.circle.service.CircleService;
import com.tuowei.dazhongdianping.module.circle.mapper.CircleMapper;
import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.community.model.PostCommentRow;
import com.tuowei.dazhongdianping.module.community.model.PostReportRow;
import com.tuowei.dazhongdianping.module.community.model.request.PostSaveRequest;
import com.tuowei.dazhongdianping.module.community.model.request.PostCommentCreateRequest;
import com.tuowei.dazhongdianping.module.community.model.request.PostReportRequest;
import com.tuowei.dazhongdianping.module.community.model.response.PostResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostLikeResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostCommentResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostReportResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostRepostResponse;
import com.tuowei.dazhongdianping.module.topic.service.TopicService;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashSet;
import java.util.List;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CommunityService {
    private static final int POST_BIZ_TYPE = 4;
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final CommunityMapper communityMapper;
    private final AdminAuditMapper adminAuditMapper;
    private final CircleService circleService;
    private final CircleMapper circleMapper;
    private final TopicService topicService;

    public CommunityService(CommunityMapper communityMapper, AdminAuditMapper adminAuditMapper,
                            CircleService circleService, CircleMapper circleMapper, TopicService topicService) {
        this.communityMapper = communityMapper;
        this.adminAuditMapper = adminAuditMapper;
        this.circleService = circleService;
        this.circleMapper = circleMapper;
        this.topicService = topicService;
    }

    @Transactional
    public PostResponse create(PostSaveRequest request) {
        UserSession user = currentUser();
        PostRow row = new PostRow();
        if (request.circleId() != null) circleService.requirePostingMembership(request.circleId(), user.userId());
        row.setUserId(user.userId());
        row.setCircleId(request.circleId());
        row.setRegion(region());
        row.setUserName(communityMapper.selectUserName(user.userId()));
        row.setTitle(request.title().trim());
        if (request.circleId() != null && !request.circleId().equals(row.getCircleId())) {
            circleService.requirePostingMembership(request.circleId(), user.userId());
        }
        row.setCircleId(request.circleId());
        row.setContent(request.content().trim());
        row.setContentType(request.contentType());
        row.setShopId(request.shopId());
        row.setDealId(request.dealId());
        communityMapper.insertPost(row);

        List<Long> topicIds = saveAssets(row.getId(), request);
        topicService.refreshPostCounts(topicIds);
        createAuditTask(row.getId());
        return ownedDetail(row.getId());
    }

    public PostResponse ownedDetail(Long postId) {
        PostRow row = communityMapper.selectOwnedPost(postId, currentUser().userId(), region());
        if (row == null) throw new NotFoundException("帖子不存在");
        return toResponse(row);
    }

    @Transactional
    public PostResponse update(Long postId, PostSaveRequest request) {
        UserSession user = currentUser();
        PostRow row = communityMapper.selectOwnedPost(postId, user.userId(), region());
        if (row == null) throw new NotFoundException("帖子不存在");
        List<Long> oldTopicIds = topicService.topicIdsForPost(postId);
        row.setTitle(request.title().trim());
        row.setContent(request.content().trim());
        row.setContentType(request.contentType());
        row.setShopId(request.shopId());
        row.setDealId(request.dealId());
        if (communityMapper.updatePost(row) == 0) throw new NotFoundException("帖子不存在");
        circleMapper.refreshPostCountByPostId(postId);
        communityMapper.deletePostImages(postId);
        communityMapper.deletePostTopics(postId);
        List<Long> newTopicIds = saveAssets(postId, request);
        LinkedHashSet<Long> affectedTopicIds = new LinkedHashSet<>(oldTopicIds);
        affectedTopicIds.addAll(newTopicIds);
        topicService.refreshPostCounts(affectedTopicIds);
        adminAuditMapper.invalidatePendingAuditTasksByBiz(POST_BIZ_TYPE, postId, "任务失效：帖子已重新提交");
        createAuditTask(postId);
        return ownedDetail(postId);
    }

    @Transactional
    public void delete(Long postId) {
        UserSession user = currentUser();
        List<Long> topicIds = topicService.topicIdsForPost(postId);
        if (communityMapper.softDeletePost(postId, user.userId(), region()) == 0) {
            throw new NotFoundException("帖子不存在");
        }
        circleMapper.refreshPostCountByPostId(postId);
        topicService.refreshPostCounts(topicIds);
        adminAuditMapper.invalidatePendingAuditTasksByBiz(POST_BIZ_TYPE, postId, "任务失效：帖子已删除");
    }

    public PostResponse publicDetail(Long postId) {
        PostRow row = communityMapper.selectPublicPost(postId, region());
        if (row == null) throw new NotFoundException("帖子不存在");
        return toResponse(row);
    }

    public PageResult<PostResponse> userPosts(Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        UserSession user = currentUser();
        long total = communityMapper.countUserPosts(user.userId(), region());
        List<PostRow> rows = communityMapper.selectUserPosts(user.userId(), region(), size, (currentPage - 1) * size);
        List<PostResponse> list = toResponses(rows);
        return new PageResult<>(list, total, currentPage, size, (currentPage - 1) * size + list.size() < total);
    }

    public PageResult<PostResponse> publicPosts(Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = communityMapper.countPublicPosts(region());
        List<PostRow> rows = communityMapper.selectPublicPosts(region(), size, (currentPage - 1) * size);
        List<PostResponse> list = toResponses(rows);
        return new PageResult<>(list, total, currentPage, size, (currentPage - 1) * size + list.size() < total);
    }

    public PageResult<PostResponse> followingPosts(Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        UserSession user = currentUser();
        long total = communityMapper.countFollowingPosts(user.userId(), region());
        List<PostRow> rows = communityMapper.selectFollowingPosts(user.userId(), region(), size, (currentPage - 1) * size);
        List<PostResponse> list = toResponses(rows);
        return new PageResult<>(list, total, currentPage, size, (currentPage - 1) * size + list.size() < total);
    }

    public PageResult<PostResponse> topicPosts(Long topicId, Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 20 : Math.min(50, Math.max(1, pageSize));
        long total = communityMapper.countTopicPosts(topicId, region());
        List<PostRow> rows = communityMapper.selectTopicPosts(topicId, region(), size, (currentPage - 1) * size);
        List<PostResponse> list = toResponses(rows);
        return new PageResult<>(list, total, currentPage, size,
                (currentPage - 1) * size + list.size() < total);
    }

    @Transactional
    public PostLikeResponse toggleLike(Long postId) {
        UserSession user = currentUser();
        requirePublicPost(postId);
        boolean liked = communityMapper.countUserPostLike(postId, user.userId()) > 0;
        if (liked) communityMapper.deletePostLike(postId, user.userId());
        else communityMapper.insertPostLike(postId, user.userId());
        communityMapper.refreshPostLikeCount(postId);
        topicService.touchTopicsByPostId(postId);
        return new PostLikeResponse(postId, !liked, communityMapper.countPostLikes(postId));
    }

    @Transactional
    public PostRepostResponse repost(Long postId) {
        UserSession user = currentUser();
        requirePublicPostForUpdate(postId);
        if (communityMapper.countUserPostRepost(postId, user.userId()) == 0) {
            try {
                communityMapper.insertPostRepost(postId, user.userId(), region());
            } catch (DuplicateKeyException ignored) {
                // Duplicate repost requests should remain idempotent.
            }
        }
        communityMapper.refreshPostRepostCount(postId);
        topicService.touchTopicsByPostId(postId);
        return new PostRepostResponse(postId, true, communityMapper.countPostReposts(postId));
    }

    @Transactional
    public PostRepostResponse removeRepost(Long postId) {
        UserSession user = currentUser();
        requirePublicPostForUpdate(postId);
        communityMapper.deletePostRepost(postId, user.userId());
        communityMapper.refreshPostRepostCount(postId);
        topicService.touchTopicsByPostId(postId);
        return new PostRepostResponse(postId, false, communityMapper.countPostReposts(postId));
    }

    @Transactional
    public PostCommentResponse createComment(Long postId, PostCommentCreateRequest request) {
        UserSession user = currentUser();
        requirePublicPost(postId);
        PostCommentRow row = new PostCommentRow();
        row.setPostId(postId);
        row.setUserId(user.userId());
        row.setUserName(communityMapper.selectUserName(user.userId()));
        row.setContent(request.content().trim());
        communityMapper.insertPostComment(row);
        communityMapper.refreshPostCommentCount(postId);
        topicService.touchTopicsByPostId(postId);
        return toComment(row);
    }

    public PageResult<PostCommentResponse> comments(Long postId, Integer page, Integer pageSize) {
        requirePublicPost(postId);
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 20 : Math.min(50, Math.max(1, pageSize));
        long total = communityMapper.countPostComments(postId);
        List<PostCommentResponse> list = communityMapper.selectPostComments(postId, size, (currentPage - 1) * size)
                .stream().map(this::toComment).toList();
        return new PageResult<>(list, total, currentPage, size, (currentPage - 1) * size + list.size() < total);
    }

    @Transactional
    public PostReportResponse report(Long postId, PostReportRequest request) {
        UserSession user = currentUser();
        PostRow post = requirePublicPost(postId);
        if (communityMapper.selectPostReport(postId, user.userId()) != null) {
            throw new IllegalArgumentException("你已经举报过这条帖子了");
        }
        PostReportRow row = new PostReportRow();
        row.setPostId(postId);
        row.setReporterUserId(user.userId());
        row.setReporterUserName(communityMapper.selectUserName(user.userId()));
        row.setReason(request.reason().trim());
        row.setStatus(0);
        communityMapper.insertPostReport(row);
        if (adminAuditMapper.selectPendingAuditTaskByBiz(POST_BIZ_TYPE, postId) == null) {
            AuditTaskRow task = new AuditTaskRow();
            task.setBizType(POST_BIZ_TYPE);
            task.setBizId(postId);
            task.setRegion(post.getRegion());
            task.setMachineResult(2);
            task.setStatus(0);
            task.setAuditorId(0L);
            task.setRemark("用户举报：" + row.getReason());
            adminAuditMapper.insertAuditTask(task);
        }
        return new PostReportResponse(row.getId(), postId, row.getReason(), 0, "待处理", format(row.getCreatedAt()));
    }

    private PostResponse toResponse(PostRow row) {
        UserSession user = UserSessionContext.get();
        boolean repostedByCurrentUser = user != null
                && communityMapper.countUserPostRepost(row.getId(), user.userId()) > 0;
        return toResponse(row, repostedByCurrentUser);
    }

    private List<PostResponse> toResponses(List<PostRow> rows) {
        if (rows.isEmpty()) return List.of();
        UserSession user = UserSessionContext.get();
        LinkedHashSet<Long> repostedPostIds = user == null
                ? new LinkedHashSet<>()
                : new LinkedHashSet<>(communityMapper.selectUserPostRepostIds(
                        rows.stream().map(PostRow::getId).toList(), user.userId()));
        return rows.stream().map(row -> toResponse(row, repostedPostIds.contains(row.getId()))).toList();
    }

    private PostResponse toResponse(PostRow row, boolean repostedByCurrentUser) {
        return new PostResponse(
                row.getId(), row.getUserId(), row.getCircleId(), row.getCircleName(), row.getUserName(), row.getTitle(), row.getContent(), row.getContentType(),
                row.getShopId(), row.getDealId(), row.getLikeCount(), row.getCommentCount(), row.getRepostCount(), repostedByCurrentUser, row.getAuditStatus(),
                auditStatusText(row.getAuditStatus()), row.getAuditRemark(), row.getStatus(),
                communityMapper.selectPostImages(row.getId()), communityMapper.selectPostTopics(row.getId()),
                format(row.getCreatedAt()), format(row.getUpdatedAt())
        );
    }

    private PostRow requirePublicPost(Long postId) {
        PostRow row = communityMapper.selectPublicPost(postId, region());
        if (row == null) throw new NotFoundException("帖子不存在");
        return row;
    }

    private PostRow requirePublicPostForUpdate(Long postId) {
        PostRow row = communityMapper.selectPublicPostForUpdate(postId, region());
        if (row == null) throw new NotFoundException("帖子不存在");
        return row;
    }

    private PostCommentResponse toComment(PostCommentRow row) {
        return new PostCommentResponse(row.getId(), row.getPostId(), row.getUserId(), row.getUserName(),
                row.getContent(), format(row.getCreatedAt()));
    }

    private List<Long> saveAssets(Long postId, PostSaveRequest request) {
        List<String> images = request.images() == null ? List.of() : request.images();
        for (int index = 0; index < images.size(); index++) {
            communityMapper.insertPostImage(postId, images.get(index).trim(), index);
        }
        List<Long> topicIds = topicService.resolveTopicIdsForPost(request.topics());
        for (Long topicId : topicIds) {
            communityMapper.insertPostTopic(postId, topicId);
        }
        return topicIds;
    }

    private void createAuditTask(Long postId) {
        AuditTaskRow task = new AuditTaskRow();
        task.setBizType(POST_BIZ_TYPE);
        task.setBizId(postId);
        task.setRegion(region());
        task.setMachineResult(0);
        task.setStatus(0);
        task.setAuditorId(0L);
        task.setRemark("");
        adminAuditMapper.insertAuditTask(task);
    }

    private UserSession currentUser() {
        UserSession session = UserSessionContext.get();
        if (session == null) throw new UnauthorizedException("用户登录状态不存在");
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private String format(java.time.LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }

    private String auditStatusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "审核通过";
            case 2 -> "审核驳回";
            default -> "待审核";
        };
    }
}
