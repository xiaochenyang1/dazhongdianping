package com.tuowei.dazhongdianping.module.admin.report;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.admin.report.mapper.AdminReportMapper;
import com.tuowei.dazhongdianping.module.admin.report.model.AdminReportRow;
import com.tuowei.dazhongdianping.module.admin.report.model.request.AdminReportResolveRequest;
import com.tuowei.dazhongdianping.module.admin.report.model.response.AdminReportResponse;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewMapper;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.review.service.ReviewService;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AdminReportService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final Set<String> REPORT_TYPES = Set.of(
            "review", "post", "message", "review_comment", "post_comment");
    private static final Set<String> ACTIONS = Set.of("dismiss", "hide");

    private final AdminReportMapper mapper;
    private final AdminAuditLogService auditLogService;
    private final ReviewMapper reviewMapper;
    private final ReviewService reviewService;

    public AdminReportService(
            AdminReportMapper mapper,
            AdminAuditLogService auditLogService,
            ReviewMapper reviewMapper,
            @Lazy ReviewService reviewService
    ) {
        this.mapper = mapper;
        this.auditLogService = auditLogService;
        this.reviewMapper = reviewMapper;
        this.reviewService = reviewService;
    }

    public PageResult<AdminReportResponse> list(
            String reportType,
            Integer status,
            String keyword,
            Integer page,
            Integer pageSize
    ) {
        String normalizedType = normalizeReportType(reportType);
        Integer normalizedStatus = normalizeStatus(status);
        String normalizedKeyword = blankToNull(keyword == null ? null : keyword.trim());
        int normalizedPage = page == null || page < 1 ? 1 : page;
        int normalizedSize = pageSize == null ? 20 : Math.max(1, Math.min(pageSize, 50));

        long total = mapper.countReports(region(), normalizedType, normalizedStatus, normalizedKeyword);
        List<AdminReportResponse> list = mapper
                .selectReports(
                        region(),
                        normalizedType,
                        normalizedStatus,
                        normalizedKeyword,
                        normalizedSize,
                        (normalizedPage - 1) * normalizedSize
                )
                .stream()
                .map(this::toResponse)
                .toList();
        return new PageResult<>(
                list,
                total,
                normalizedPage,
                normalizedSize,
                (long) normalizedPage * normalizedSize < total
        );
    }

    @Transactional
    public AdminReportResponse resolve(
            String reportType,
            Long id,
            AdminReportResolveRequest request,
            String requestIp
    ) {
        String type = requireReportType(reportType);
        String action = normalizeAction(request.action());
        String remark = request.remark() == null ? "" : request.remark().trim();
        if ("hide".equals(action) && !StringUtils.hasText(remark)) {
            remark = "平台处理举报后隐藏内容";
        }

        AdminReportRow row = requireReport(type, id);
        if (row.getStatus() != null && row.getStatus() != 0) {
            throw new IllegalArgumentException("举报已处理");
        }

        int nextStatus = "hide".equals(action) ? 1 : 2;
        if ("review".equals(type)) {
            if (mapper.resolveReviewReport(id, nextStatus) != 1) {
                throw new IllegalArgumentException("举报状态已变更");
            }
            if ("hide".equals(action)) {
                mapper.hideReview(row.getTargetId(), region(), remark);
                mapper.resolvePendingReviewReports(row.getTargetId());
                ReviewRow review = reviewMapper.selectReviewById(row.getTargetId());
                if (review != null && review.getShopId() != null) {
                    reviewService.recalculateShopAggregate(review.getShopId());
                }
            }
        } else if ("post".equals(type)) {
            if (mapper.resolvePostReport(id, nextStatus) != 1) {
                throw new IllegalArgumentException("举报状态已变更");
            }
            if ("hide".equals(action)) {
                mapper.hidePost(row.getTargetId(), region(), remark);
                mapper.resolvePendingPostReports(row.getTargetId());
            }
        } else if ("review_comment".equals(type)) {
            if (mapper.resolveReviewCommentReport(id, nextStatus) != 1) {
                throw new IllegalArgumentException("举报状态已变更");
            }
            if ("hide".equals(action)) {
                mapper.hideReviewComment(row.getTargetId(), region(), remark);
                mapper.resolvePendingReviewCommentReports(row.getTargetId());
                mapper.refreshReviewCommentCountByCommentId(row.getTargetId());
            }
        } else if ("post_comment".equals(type)) {
            if (mapper.resolvePostCommentReport(id, nextStatus) != 1) {
                throw new IllegalArgumentException("举报状态已变更");
            }
            if ("hide".equals(action)) {
                mapper.hidePostComment(row.getTargetId(), region(), remark);
                mapper.resolvePendingPostCommentReports(row.getTargetId());
                mapper.refreshPostCommentCountByCommentId(row.getTargetId());
            }
        } else {
            if (mapper.resolveMessageReport(id, nextStatus) != 1) {
                throw new IllegalArgumentException("举报状态已变更");
            }
        }

        AdminReportRow refreshed = requireReport(type, id);
        auditLogService.record(
                currentAdmin().adminId(),
                "hide".equals(action) ? "audit_report_hide" : "audit_report_dismiss",
                type + "_report:" + id,
                "targetId=" + row.getTargetId() + ", reason=" + row.getReason() + ", remark=" + remark,
                requestIp == null ? "" : requestIp
        );
        return toResponse(refreshed);
    }

    private AdminReportRow requireReport(String type, Long id) {
        AdminReportRow row = switch (type) {
            case "review" -> mapper.selectReviewReport(id, region());
            case "post" -> mapper.selectPostReport(id, region());
            case "message" -> mapper.selectMessageReport(id);
            case "review_comment" -> mapper.selectReviewCommentReport(id, region());
            case "post_comment" -> mapper.selectPostCommentReport(id, region());
            default -> null;
        };
        if (row == null) {
            throw new NotFoundException("举报不存在");
        }
        return row;
    }

    private AdminReportResponse toResponse(AdminReportRow row) {
        return new AdminReportResponse(
                row.getId(),
                row.getReportType(),
                reportTypeText(row.getReportType()),
                row.getTargetId(),
                row.getTargetType(),
                targetTypeText(row.getReportType(), row.getTargetType()),
                row.getReporterUserId(),
                row.getReporterUserName() == null ? "" : row.getReporterUserName(),
                row.getReason() == null ? "" : row.getReason(),
                row.getStatus() == null ? 0 : row.getStatus(),
                statusText(row.getStatus()),
                row.getRegion() == null ? "" : row.getRegion(),
                row.getTargetSummary() == null ? "" : row.getTargetSummary(),
                row.getTargetAuthorId(),
                row.getTargetAuthorName() == null ? "" : row.getTargetAuthorName(),
                row.getTargetAuditStatus(),
                row.getTargetStatus(),
                targetStatusText(row.getReportType(), row.getTargetAuditStatus()),
                row.getCreatedAt() == null ? "" : row.getCreatedAt().format(FORMATTER)
        );
    }

    private String reportTypeText(String type) {
        if (type == null) {
            return "";
        }
        return switch (type) {
            case "review" -> "点评举报";
            case "post" -> "帖子举报";
            case "message" -> "私信举报";
            case "review_comment" -> "点评评论举报";
            case "post_comment" -> "帖子评论举报";
            default -> type;
        };
    }

    private String targetTypeText(String reportType, Integer targetType) {
        if (!"message".equals(reportType) || targetType == null) {
            return "";
        }
        return targetType == 1 ? "消息" : "会话";
    }

    private String statusText(Integer status) {
        if (status == null) {
            return "待处理";
        }
        return switch (status) {
            case 1 -> "已成立";
            case 2 -> "已驳回";
            default -> "待处理";
        };
    }

    private String targetStatusText(String reportType, Integer auditStatus) {
        if ("message".equals(reportType)) {
            return "私信";
        }
        if ("review_comment".equals(reportType) || "post_comment".equals(reportType)) {
            if (auditStatus == null) {
                return "";
            }
            return switch (auditStatus) {
                case 2 -> "已隐藏";
                case 1 -> "公开";
                default -> "待审";
            };
        }
        if (auditStatus == null) {
            return "";
        }
        return switch (auditStatus) {
            case 1 -> "公开";
            case 2 -> "已隐藏/驳回";
            default -> "待审";
        };
    }

    private String normalizeReportType(String reportType) {
        if (!StringUtils.hasText(reportType)) {
            return null;
        }
        String value = reportType.trim().toLowerCase(Locale.ROOT);
        if (!REPORT_TYPES.contains(value)) {
            throw new IllegalArgumentException("reportType 仅支持 review/post/message/review_comment/post_comment");
        }
        return value;
    }

    private String requireReportType(String reportType) {
        String value = normalizeReportType(reportType);
        if (value == null) {
            throw new IllegalArgumentException("reportType 不能为空");
        }
        return value;
    }

    private Integer normalizeStatus(Integer status) {
        if (status == null) {
            return null;
        }
        if (status < 0 || status > 2) {
            throw new IllegalArgumentException("status 仅支持 0/1/2");
        }
        return status;
    }

    private String normalizeAction(String action) {
        if (!StringUtils.hasText(action)) {
            throw new IllegalArgumentException("action 不能为空");
        }
        String value = action.trim().toLowerCase(Locale.ROOT);
        if (!ACTIONS.contains(value)) {
            throw new IllegalArgumentException("action 仅支持 dismiss/hide");
        }
        return value;
    }

    private String blankToNull(String value) {
        return StringUtils.hasText(value) ? value : null;
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
