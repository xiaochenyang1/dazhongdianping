package com.tuowei.dazhongdianping.module.creator.service;

import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.*;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.creator.mapper.CreatorMapper;
import com.tuowei.dazhongdianping.module.creator.model.CreatorClaimRow;
import com.tuowei.dazhongdianping.module.creator.model.request.*;
import com.tuowei.dazhongdianping.module.launch.LaunchPolicy;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CreatorReviewService {
    private final CreatorMapper mapper;
    private final AuthCommandMapper accounts;
    private final AdminAuditLogService audit;
    private final LaunchPolicy launch;

    public CreatorReviewService(CreatorMapper mapper, AuthCommandMapper accounts,
                               AdminAuditLogService audit, LaunchPolicy launch) {
        this.mapper = mapper;
        this.accounts = accounts;
        this.audit = audit;
        this.launch = launch;
    }

    public PageResult<Map<String, Object>> evidence(String type, int page, int pageSize) {
        launch.require(LaunchPolicy.Feature.CREATOR_REWARDS);
        checkType(type);
        long userId = userId();
        checkPage(page, pageSize);
        var rows = mapper.selectEligibleEvidence(type, userId, region(), pageSize, (page - 1) * pageSize);
        long count = mapper.countEligibleEvidence(type, userId, region());
        return new PageResult<>(rows, count, page, pageSize, (long) page * pageSize < count);
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Map<String, Object> submit(Long taskId, CreatorSubmissionRequest request) {
        launch.require(LaunchPolicy.Feature.CREATOR_REWARDS);
        long userId = userId();
        lockOwner(userId);
        CreatorClaimRow row = mapper.selectClaim(taskId, userId);
        if (row == null || !region().equals(row.getRegion())) throw new NotFoundException("请先领取当前区域的任务");
        row = mapper.lockClaim(row.getId(), region());
        if (row == null) throw new NotFoundException("成果不存在");
        String note = trim(request.note());
        if (row.getStatus() == 3 && request.evidenceType().equals(row.getEvidenceType())
                && request.evidenceId().equals(row.getEvidenceId()) && note.equals(row.getSubmissionNote())) {
            return present(row); // Safe retry after a lost submission response.
        }
        if (row.getStatus() != 1 && row.getStatus() != 4) throw new ConflictException("当前任务不可重复提交成果");
        checkType(request.evidenceType());
        if (mapper.selectEvidence(request.evidenceType(), request.evidenceId(), userId, region(), true) == null) {
            throw new NotFoundException("请选择本人在当前区域已发布的点评或帖子");
        }
        row.setEvidenceType(request.evidenceType());
        row.setEvidenceId(request.evidenceId());
        row.setSubmissionNote(note);
        if (mapper.submitClaim(row) != 1) throw new ConflictException("成果状态已变化，请刷新后重试");
        return present(mapper.selectClaimById(row.getId(), region()));
    }

    public PageResult<Map<String, Object>> claims(Integer status, int page, int pageSize) {
        if (status != null && (status < 1 || status > 4)) throw new IllegalArgumentException("无效审核状态");
        checkPage(page, pageSize);
        var rows = mapper.selectClaims(region(), status, pageSize, (page - 1) * pageSize).stream().map(this::present).toList();
        long count = mapper.countClaims(region(), status);
        return new PageResult<>(rows, count, page, pageSize, (long) page * pageSize < count);
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Map<String, Object> review(Long id, CreatorReviewRequest request, String ip) {
        var admin = AdminSessionContext.get();
        if (admin == null) throw new UnauthorizedException("管理员登录状态不存在");
        if (request.approved()) launch.require(LaunchPolicy.Feature.CREATOR_REWARDS);
        CreatorClaimRow row = mapper.selectClaimById(id, region());
        if (row == null) throw new NotFoundException("成果不存在");
        // Match privacy export/deletion lock order: account, claim, then content.
        lockOwner(row.getUserId());
        row = mapper.lockClaim(id, region());
        if (row == null) throw new NotFoundException("成果不存在");
        if (!request.submissionVersion().equals(row.getSubmissionVersion())) {
            throw new ConflictException("成果已重新提交，请刷新后审核");
        }
        int decision = request.approved() ? 2 : 4;
        if (row.getStatus() == decision) return present(row);
        if (row.getStatus() != 3) throw new ConflictException("成果已处理，请刷新列表");
        String note = trim(request.note());
        if (!request.approved() && note.isEmpty()) throw new IllegalArgumentException("请填写驳回原因");
        if (request.approved()) {
            if (request.evidenceHash() == null) throw new IllegalArgumentException("请先查看最新成果再审核");
            var evidence = evidenceDetail(row, true);
            if (evidence == null) throw new ConflictException("成果已删除或不再公开，请驳回后重新提交");
            if (!hash(evidence).equals(request.evidenceHash())) throw new ConflictException("成果内容已变化，请刷新后重新审核");
            int reward = row.getRewardPoints() == null ? 0 : row.getRewardPoints();
            int balance = mapper.selectUserPoints(row.getUserId());
            if ((long) balance + reward > Integer.MAX_VALUE) throw new ConflictException("积分余额超出范围");
            if (mapper.addUserPoints(row.getUserId(), reward) != 1) throw new ConflictException("账户不可用");
            mapper.insertPointsLog(row.getUserId(), row.getId(), reward, balance + reward, "创作者任务审核通过");
        }
        row.setStatus(decision);
        row.setReviewedBy(admin.adminId());
        row.setReviewNote(note);
        if (mapper.reviewClaim(row) != 1) throw new ConflictException("成果状态已变化，请刷新后重试");
        audit.record(admin.adminId(), request.approved() ? "creator.claim.approve" : "creator.claim.reject",
                "creator_claim:" + id, "submission=" + row.getSubmissionVersion()
                        + (request.approved() ? ";evidence_sha256=" + request.evidenceHash() : ""), ip);
        return present(mapper.selectClaimById(id, region()));
    }

    private Map<String, Object> present(CreatorClaimRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId()); result.put("taskId", row.getTaskId());
        result.put("claimId", row.getId()); result.put("userId", row.getUserId());
        result.put("taskTitle", row.getTaskTitle()); result.put("taskDescription", row.getTaskDescription());
        result.put("rewardPoints", row.getRewardPoints()); result.put("claimStatus", row.getStatus());
        result.put("evidenceType", row.getEvidenceType()); result.put("evidenceId", row.getEvidenceId());
        result.put("submissionNote", row.getSubmissionNote()); result.put("submissionVersion", row.getSubmissionVersion());
        result.put("submittedAt", row.getSubmittedAt()); result.put("reviewNote", row.getReviewNote());
        result.put("reviewedAt", row.getReviewedAt()); result.put("completedAt", row.getCompletedAt());
        var evidence = evidenceDetail(row, false);
        result.put("evidence", evidence); result.put("evidenceHash", evidence == null ? null : hash(evidence));
        return result;
    }

    private Map<String, Object> evidenceDetail(CreatorClaimRow row, boolean lock) {
        if (row.getEvidenceId() == null) return null;
        var evidence = mapper.selectEvidence(row.getEvidenceType(), row.getEvidenceId(), row.getUserId(), row.getRegion(), lock);
        if (evidence != null) {
            evidence.put("images", mapper.selectEvidenceImages(row.getEvidenceType(), row.getEvidenceId()));
        }
        return evidence;
    }

    private void lockOwner(Long userId) {
        var user = userId == null ? null : accounts.selectUserByIdForUpdate(userId);
        if (user == null || user.getStatus() == null || user.getStatus() != 1) throw new ConflictException("账户已停用，无法处理成果");
    }

    private long userId() {
        var user = UserSessionContext.get();
        if (user == null) throw new UnauthorizedException("用户登录状态不存在");
        return user.userId();
    }

    private static void checkType(String type) {
        if (!"review".equals(type) && !"post".equals(type)) throw new IllegalArgumentException("请选择点评或帖子");
    }
    private static void checkPage(int page, int size) {
        if (page < 1 || page > 1000000 || size < 1 || size > 50) throw new IllegalArgumentException("无效分页参数");
    }
    private static String trim(String value) { return value == null ? "" : value.trim(); }
    private static String region() { return RegionContext.getRegion().name(); }
    private static String hash(Map<String, Object> evidence) {
        try {
            StringBuilder snapshot = new StringBuilder();
            for (String key : List.of("id", "title", "content", "shopId", "score", "createdAt", "updatedAt")) {
                appendHashField(snapshot, String.valueOf(evidence.get(key)));
            }
            var images = (List<?>) evidence.get("images");
            appendHashField(snapshot, String.valueOf(images.size()));
            for (Object url : images) appendHashField(snapshot, String.valueOf(url));
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(snapshot.toString().getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) { throw new IllegalStateException(exception); }
    }

    private static void appendHashField(StringBuilder target, String value) {
        target.append(value.length()).append(':').append(value);
    }
}
