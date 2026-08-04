package com.tuowei.dazhongdianping.module.points.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.points.mapper.PointsMapper;
import com.tuowei.dazhongdianping.module.points.model.PointsProductRow;
import com.tuowei.dazhongdianping.module.points.model.request.PointsProductSaveRequest;
import com.tuowei.dazhongdianping.module.points.model.response.PointsProductResponse;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminPointsProductService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final PointsMapper pointsMapper;
    private final AdminAuditLogService auditLogService;

    public AdminPointsProductService(PointsMapper pointsMapper, AdminAuditLogService auditLogService) {
        this.pointsMapper = pointsMapper;
        this.auditLogService = auditLogService;
    }

    public PageResult<PointsProductResponse> list(Integer page, Integer pageSize) {
        int currentPage = page == null || page < 1 ? 1 : page;
        int size = pageSize == null ? 20 : Math.max(1, Math.min(pageSize, 50));
        String region = region();
        long total = pointsMapper.countProductsByRegion(region);
        List<PointsProductResponse> items = pointsMapper
                .selectProductsByRegion(region, size, (currentPage - 1) * size)
                .stream()
                .map(this::toResponse)
                .toList();
        return new PageResult<>(items, total, currentPage, size, (long) currentPage * size < total);
    }

    @Transactional
    public PointsProductResponse create(PointsProductSaveRequest request, String requestIp) {
        PointsProductRow row = new PointsProductRow();
        row.setRegion(region());
        row.setName(request.getName().trim());
        row.setCoverImage(request.getCoverImage() == null ? "" : request.getCoverImage().trim());
        row.setDescription(request.getDescription() == null ? "" : request.getDescription().trim());
        row.setPointsPrice(request.getPointsPrice());
        row.setStock(request.getStock());
        row.setExchangeLimitPerUser(request.getExchangeLimitPerUser() == null ? 0 : request.getExchangeLimitPerUser());
        row.setFulfillType(normalizeFulfillType(request.getFulfillType()));
        row.setSort(request.getSort() == null ? 0 : request.getSort());
        row.setStatus(1);
        pointsMapper.insertProduct(row);

        PointsProductResponse response = toResponse(require(row.getId()));
        record("admin.points_product_create", "points_product:" + row.getId(), response, requestIp);
        return response;
    }

    @Transactional
    public PointsProductResponse update(Long id, PointsProductSaveRequest request, String requestIp) {
        require(id);
        PointsProductRow row = new PointsProductRow();
        row.setId(id);
        row.setRegion(region());
        row.setName(request.getName().trim());
        row.setCoverImage(request.getCoverImage() == null ? "" : request.getCoverImage().trim());
        row.setDescription(request.getDescription() == null ? "" : request.getDescription().trim());
        row.setPointsPrice(request.getPointsPrice());
        row.setStock(request.getStock());
        row.setExchangeLimitPerUser(request.getExchangeLimitPerUser() == null ? 0 : request.getExchangeLimitPerUser());
        row.setFulfillType(normalizeFulfillType(request.getFulfillType()));
        row.setSort(request.getSort() == null ? 0 : request.getSort());
        if (pointsMapper.updateProduct(row) != 1) {
            throw new NotFoundException("积分商品不存在");
        }
        PointsProductResponse response = toResponse(require(id));
        record("admin.points_product_update", "points_product:" + id, response, requestIp);
        return response;
    }

    @Transactional
    public PointsProductResponse updateStatus(Long id, Integer status, String requestIp) {
        require(id);
        if (pointsMapper.updateProductStatus(id, region(), status) != 1) {
            throw new NotFoundException("积分商品不存在");
        }
        PointsProductResponse response = toResponse(require(id));
        record("admin.points_product_status", "points_product:" + id, response, requestIp);
        return response;
    }

    @Transactional
    public void delete(Long id, String requestIp) {
        require(id);
        if (pointsMapper.softDeleteProduct(id, region()) != 1) {
            throw new NotFoundException("积分商品不存在");
        }
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.points_product_delete",
                "points_product:" + id,
                "id=" + id,
                requestIp
        );
    }

    private PointsProductRow require(Long id) {
        PointsProductRow row = pointsMapper.selectProductById(id, region());
        if (row == null) {
            throw new NotFoundException("积分商品不存在");
        }
        return row;
    }

    private PointsProductResponse toResponse(PointsProductRow row) {
        int fulfillType = normalizeFulfillType(row.getFulfillType());
        return new PointsProductResponse(
                row.getId(),
                row.getRegion(),
                row.getName(),
                row.getCoverImage() == null ? "" : row.getCoverImage(),
                row.getDescription() == null ? "" : row.getDescription(),
                row.getPointsPrice() == null ? 0 : row.getPointsPrice(),
                row.getStock() == null ? 0 : row.getStock(),
                row.getExchangeLimitPerUser() == null ? 0 : row.getExchangeLimitPerUser(),
                row.getExchangeCount() == null ? 0 : row.getExchangeCount(),
                fulfillType,
                PointsMallService.fulfillTypeText(fulfillType),
                row.getStatus() == null ? 1 : row.getStatus(),
                row.getSort() == null ? 0 : row.getSort(),
                row.getStock() != null && row.getStock() <= 0,
                format(row.getCreatedAt()),
                format(row.getUpdatedAt())
        );
    }

    private int normalizeFulfillType(Integer fulfillType) {
        return fulfillType != null && fulfillType == 2 ? 2 : 1;
    }

    private void record(String action, String target, PointsProductResponse response, String requestIp) {
        auditLogService.record(
                currentAdmin().adminId(),
                action,
                target,
                "name=" + response.name() + ", pointsPrice=" + response.pointsPrice()
                        + ", stock=" + response.stock() + ", status=" + response.status(),
                requestIp
        );
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员未登录");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private String format(java.time.LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }
}
