package com.tuowei.dazhongdianping.module.creator.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.module.launch.LaunchPolicy;
import com.tuowei.dazhongdianping.module.launch.LaunchPolicy.Feature;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.creator.mapper.CreatorMapper;
import com.tuowei.dazhongdianping.module.creator.model.CreatorClaimRow;
import com.tuowei.dazhongdianping.module.creator.model.CreatorTaskRow;
import com.tuowei.dazhongdianping.module.creator.model.request.CreatorTaskSaveRequest;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 创作者任务：领取时冻结任务要求和奖励，发奖由成果审核完成。 */
@Service
public class CreatorService {

    private final CreatorMapper mapper;
    private final LaunchPolicy launch;
    private final AuthCommandMapper accounts;

    public CreatorService(CreatorMapper mapper, LaunchPolicy launch, AuthCommandMapper accounts) {
        this.accounts = accounts;
        this.mapper = mapper;
        this.launch = launch;
    }

    public PageResult<Map<String, Object>> tasks(Integer page, Integer pageSize) {
        launch.require(Feature.CREATOR_REWARDS);
        UserSession user = requireUser();
        String region = region();
        int p = page(page);
        int s = pageSize(pageSize);
        long total = mapper.countOpen(region, user.userId());
        List<Map<String, Object>> list = mapper.selectOpen(region, user.userId(), s, (p - 1) * s)
                .stream().map(this::openMap).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> claim(Long taskId) {
        launch.require(Feature.CREATOR_REWARDS);
        UserSession user = requireUser();
        String region = region();
        var owner = accounts.selectUserByIdForUpdate(user.userId());
        if (owner == null || owner.getStatus() != 1) throw new NotFoundException("用户不可用");
        CreatorTaskRow task = mapper.lockTask(taskId, region);
        if (task == null || task.getStatus() != 1) throw new NotFoundException("任务不存在");
        CreatorClaimRow existing = mapper.selectClaim(taskId, user.userId());
        if (existing != null) {
            throw new IllegalArgumentException("任务已领取");
        }
        CreatorClaimRow claim = new CreatorClaimRow();
        claim.setTaskId(task.getId());
        claim.setUserId(user.userId());
        claim.setRegion(region);
        claim.setStatus(1);
        claim.setTaskTitle(task.getTitle());
        claim.setTaskDescription(task.getDescription());
        claim.setRewardPoints(task.getRewardPoints());
        try {
            mapper.insertClaim(claim);
        } catch (DuplicateKeyException exception) {
            throw new IllegalArgumentException("任务已领取");
        }
        return claimMap(task.getId(), claim.getId(), 1, null, null);
    }

    public Map<String, Object> complete(Long taskId) {
        launch.require(Feature.CREATOR_REWARDS);
        requireUser();
        throw new ConflictException("请提交成果，审核通过后发放积分");
    }

    public PageResult<Map<String, Object>> adminList(Integer page, Integer pageSize) {
        String region = region();
        int p = page(page);
        int s = pageSize(pageSize);
        long total = mapper.countAdmin(region);
        List<Map<String, Object>> list = mapper.selectAdmin(region, s, (p - 1) * s)
                .stream().map(this::adminMap).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> create(CreatorTaskSaveRequest request) {
        CreatorTaskRow row = new CreatorTaskRow();
        row.setRegion(region());
        fill(row, request);
        mapper.insertTask(row);
        return adminMap(requireTask(row.getId(), row.getRegion()));
    }

    @Transactional
    public Map<String, Object> update(Long id, CreatorTaskSaveRequest request) {
        CreatorTaskRow row = requireTask(id, region());
        fill(row, request);
        if (mapper.updateTask(row) == 0) {
            throw new NotFoundException("任务不存在");
        }
        return adminMap(requireTask(id, region()));
    }

    private void fill(CreatorTaskRow row, CreatorTaskSaveRequest request) {
        row.setTitle(request.title().trim());
        row.setDescription(request.description() == null ? "" : request.description().trim());
        row.setRewardPoints(request.rewardPoints());
        row.setStatus(taskStatus(request.status()));
    }

    private CreatorTaskRow requireTask(Long id, String region) {
        CreatorTaskRow task = mapper.selectTask(id, region);
        if (task == null) {
            throw new NotFoundException("任务不存在");
        }
        return task;
    }

    private Map<String, Object> openMap(CreatorTaskRow row) {
        Map<String, Object> map = adminMap(row);
        map.put("claimStatus", row.getClaimStatus() == null ? 0 : row.getClaimStatus());
        map.put("claimId", row.getClaimId());
        map.put("reviewNote", row.getReviewNote());
        map.put("evidenceType", row.getEvidenceType());
        map.put("evidenceId", row.getEvidenceId());
        map.put("submissionNote", row.getSubmissionNote());
        map.put("submissionVersion", row.getSubmissionVersion());
        return map;
    }

    private Map<String, Object> adminMap(CreatorTaskRow row) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("title", row.getTitle());
        map.put("description", row.getDescription() == null ? "" : row.getDescription());
        map.put("rewardPoints", row.getRewardPoints() == null ? 0 : row.getRewardPoints());
        map.put("status", row.getStatus());
        map.put("createdAt", row.getCreatedAt());
        return map;
    }

    private Map<String, Object> claimMap(Long taskId, Long claimId, int claimStatus, Integer rewardPoints, Integer points) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("taskId", taskId);
        map.put("claimId", claimId);
        map.put("claimStatus", claimStatus);
        if (rewardPoints != null) {
            map.put("rewardPoints", rewardPoints);
        }
        if (points != null) {
            map.put("points", points);
        }
        return map;
    }

    private int taskStatus(Integer status) {
        if (status == null) {
            return 1;
        }
        if (status != 0 && status != 1) {
            throw new IllegalArgumentException("status 只能是 0 或 1");
        }
        return status;
    }

    private UserSession requireUser() {
        UserSession user = UserSessionContext.get();
        if (user == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return user;
    }

    private int page(Integer page) {
        return page == null ? 1 : Math.max(1, page);
    }

    private int pageSize(Integer pageSize) {
        return pageSize == null ? 10 : Math.min(50, Math.max(1, pageSize));
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
