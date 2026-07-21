package com.tuowei.dazhongdianping.module.admin.banner;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.banner.mapper.AdminBannerMapper;
import com.tuowei.dazhongdianping.module.admin.banner.model.AdminBannerRow;
import com.tuowei.dazhongdianping.module.admin.banner.model.request.AdminBannerSaveRequest;
import com.tuowei.dazhongdianping.module.admin.banner.model.response.AdminBannerResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminBannerService {

    private final AdminBannerMapper mapper;
    private final AdminAuditLogService auditLogService;

    public AdminBannerService(AdminBannerMapper mapper,
                              AdminAuditLogService auditLogService) {
        this.mapper = mapper;
        this.auditLogService = auditLogService;
    }

    public List<AdminBannerResponse> list(Long cityId) {
        return mapper.selectBanners(region(), cityId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public AdminBannerResponse create(AdminBannerSaveRequest request, String requestIp) {
        Long cityId = request.cityId();
        ensureCityAvailable(cityId);

        AdminBannerRow row = new AdminBannerRow();
        row.setId(nextId());
        row.setCityId(cityId);
        row.setRegion(region());
        row.setTitle(request.title().trim());
        row.setSubtitle(text(request.subtitle()));
        row.setImageUrl(request.imageUrl().trim());
        row.setLinkUrl(normalizeLinkUrl(request.linkUrl()));
        row.setEnabled(true);
        row.setSortNo(request.sortNo());
        mapper.insertBanner(row);

        AdminBannerResponse response = toResponse(require(row.getId()));
        record("admin.banner_create", "banner:" + row.getId(), response, requestIp);
        return response;
    }

    @Transactional
    public AdminBannerResponse update(Long id, AdminBannerSaveRequest request, String requestIp) {
        AdminBannerRow row = require(id);
        Long cityId = request.cityId();
        ensureCityAvailable(cityId);

        row.setCityId(cityId);
        row.setTitle(request.title().trim());
        row.setSubtitle(text(request.subtitle()));
        row.setImageUrl(request.imageUrl().trim());
        row.setLinkUrl(normalizeLinkUrl(request.linkUrl()));
        row.setSortNo(request.sortNo());
        if (mapper.updateBanner(row) != 1) {
            throw new NotFoundException("Banner 不存在");
        }

        AdminBannerResponse response = toResponse(require(id));
        record("admin.banner_update", "banner:" + id, response, requestIp);
        return response;
    }

    @Transactional
    public AdminBannerResponse updateStatus(Long id, boolean enabled, String requestIp) {
        AdminBannerRow existing = require(id);
        if (mapper.updateBannerStatus(id, region(), enabled) != 1) {
            throw new NotFoundException("Banner 不存在");
        }
        AdminBannerResponse response = toResponse(require(id));
        String detail = String.format(
                "title=%s, enabled=%s -> %s",
                existing.getTitle(),
                Boolean.TRUE.equals(existing.getEnabled()),
                enabled
        );
        auditLogService.record(currentAdmin().adminId(), "admin.banner_status", "banner:" + id, detail, requestIp);
        return response;
    }

    @Transactional
    public void delete(Long id, String requestIp) {
        AdminBannerRow existing = require(id);
        if (mapper.deleteBanner(id, region()) != 1) {
            throw new NotFoundException("Banner 不存在");
        }
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.banner_delete",
                "banner:" + id,
                "title=" + existing.getTitle(),
                requestIp
        );
    }

    private AdminBannerRow require(Long id) {
        AdminBannerRow row = mapper.selectBanner(id, region());
        if (row == null) {
            throw new NotFoundException("Banner 不存在");
        }
        return row;
    }

    private Long nextId() {
        Long next = mapper.selectNextBannerId();
        return next == null || next < 1 ? 1L : next;
    }

    private void ensureCityAvailable(Long cityId) {
        if (cityId == null) {
            return;
        }
        Integer count = mapper.countActiveCity(cityId, region());
        if (count == null || count == 0) {
            throw new ConflictException("当前区域城市不存在或已停用");
        }
    }

    private AdminBannerResponse toResponse(AdminBannerRow row) {
        return new AdminBannerResponse(
                row.getId(),
                row.getRegion(),
                row.getCityId(),
                row.getCityName() == null ? "" : row.getCityName(),
                row.getTitle(),
                row.getSubtitle() == null ? "" : row.getSubtitle(),
                row.getImageUrl(),
                row.getLinkUrl(),
                Boolean.TRUE.equals(row.getEnabled()),
                row.getSortNo() == null ? 0 : row.getSortNo()
        );
    }

    private void record(String action, String target, AdminBannerResponse response, String requestIp) {
        String detail = String.format(
                "region=%s, cityId=%s, title=%s, enabled=%s, sortNo=%d",
                response.region(),
                response.cityId() == null ? "GLOBAL" : response.cityId(),
                response.title(),
                response.enabled(),
                response.sortNo()
        );
        auditLogService.record(currentAdmin().adminId(), action, target, detail, requestIp);
    }

    private String normalizeLinkUrl(String value) {
        String normalized = value.trim();
        if (!normalized.startsWith("/")) {
            throw new IllegalArgumentException("linkUrl 仅支持站内相对路径");
        }
        return normalized;
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
