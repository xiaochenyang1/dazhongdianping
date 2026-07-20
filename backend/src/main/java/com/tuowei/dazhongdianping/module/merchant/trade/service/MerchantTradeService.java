package com.tuowei.dazhongdianping.module.merchant.trade.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.merchant.trade.mapper.MerchantTradeMapper;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantDealSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantRefundAuditRequest;
import com.tuowei.dazhongdianping.module.trade.model.DealItemRow;
import com.tuowei.dazhongdianping.module.trade.model.DealRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantTradeService {

    private static final int DEAL_AUDIT_BIZ_TYPE = 2;

    private final MerchantTradeMapper mapper;
    private final AdminAuditMapper adminAuditMapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantTradeService(MerchantTradeMapper mapper,
                                AdminAuditMapper adminAuditMapper,
                                MerchantAuthorizationService authorizationService) {
        this.mapper = mapper;
        this.adminAuditMapper = adminAuditMapper;
        this.authorizationService = authorizationService;
    }

    public PageResult<Map<String, Object>> deals(Long shopId,
                                                  Integer auditStatus,
                                                  Integer status,
                                                  Integer page,
                                                  Integer pageSize) {
        MerchantSession session = merchant();
        authorizationService.requirePermission(session, "deal:edit");
        if (shopId != null) {
            authorizationService.requireShop(session, "deal:edit", shopId);
        }
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        List<Long> scopedShopIds = shopId == null ? authorizationService.scopedShopIds(session) : null;
        long total = mapper.countDeals(session.merchantId(), region(), shopId, scopedShopIds, auditStatus, status);
        List<Map<String, Object>> list = mapper.selectDeals(
                session.merchantId(), region(), shopId, scopedShopIds, auditStatus, status,
                normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(row -> dealMap(row, false)).toList();
        return new PageResult<>(
                list,
                total,
                normalizedPage,
                normalizedPageSize,
                (long) normalizedPage * normalizedPageSize < total
        );
    }

    @Transactional
    public Map<String, Object> createDeal(MerchantDealSaveRequest request) {
        MerchantSession session = merchant();
        authorizationService.requireShop(session, "deal:edit", request.shopId());
        validate(request);
        DealRow row = toRow(request, session);
        mapper.insertDeal(row);
        mapper.insertDealItems(row.getId(), request.items());
        createAuditTask(row);
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), "deal_create", "deal", row.getId(), request.title().trim()
        );
        return dealMap(requireDeal(row.getId(), session), true);
    }

    @Transactional
    public Map<String, Object> updateDeal(Long dealId, MerchantDealSaveRequest request) {
        MerchantSession session = merchant();
        DealRow existing = requireDeal(dealId, session);
        authorizationService.requireShop(session, "deal:edit", existing.getShopId());
        authorizationService.requireShop(session, "deal:edit", request.shopId());
        validate(request);
        if (mapper.countPaidOrders(dealId) > 0
                && (!existing.getShopId().equals(request.shopId())
                || !existing.getType().equals(request.type())
                || existing.getPrice().compareTo(request.price()) != 0
                || !existing.getCurrency().equalsIgnoreCase(request.currency()))) {
            throw new IllegalArgumentException("已售团购不能修改门店、类型、售价或币种");
        }
        DealRow row = toRow(request, session);
        row.setId(dealId);
        if (mapper.updateDeal(row) == 0) {
            throw new IllegalArgumentException("团购状态已变化，请刷新后重试");
        }
        mapper.deleteDealItems(dealId);
        mapper.insertDealItems(dealId, request.items());
        adminAuditMapper.invalidatePendingAuditTasksByBiz(DEAL_AUDIT_BIZ_TYPE, dealId, "团购已重新提交");
        createAuditTask(row);
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), "deal_update", "deal", dealId, request.title().trim()
        );
        return dealMap(requireDeal(dealId, session), true);
    }

    @Transactional
    public Map<String, Object> changeDealStatus(Long dealId, Integer status) {
        MerchantSession session = merchant();
        DealRow existing = requireDeal(dealId, session);
        authorizationService.requireShop(session, "deal:edit", existing.getShopId());
        if (mapper.changeDealStatus(dealId, session.merchantId(), region(), status) == 0) {
            throw new IllegalArgumentException(status == 1 ? "团购未审核通过、已过期或无库存，不能上架" : "团购状态已变化");
        }
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), status == 1 ? "deal_on_shelf" : "deal_off_shelf",
                "deal", dealId, ""
        );
        return dealMap(requireDeal(dealId, session), true);
    }

    public PageResult<Map<String, Object>> orders(
            Long shopId,
            Integer payStatus,
            Integer refundStatus,
            String orderNo,
            LocalDate dateFrom,
            LocalDate dateTo,
            Integer page,
            Integer pageSize
    ) {
        MerchantSession session = merchant();
        authorizationService.requirePermission(session, "order:view");
        if (shopId != null) {
            authorizationService.requireShop(session, "order:view", shopId);
        }
        validateDateRange(dateFrom, dateTo);
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        List<Long> scopedShopIds = shopId == null ? authorizationService.scopedShopIds(session) : null;
        if (scopedShopIds != null && scopedShopIds.isEmpty()) {
            return new PageResult<>(List.of(), 0, normalizedPage, normalizedPageSize, false);
        }
        String normalizedOrderNo = orderNo == null || orderNo.isBlank() ? null : orderNo.trim();
        LocalDate dateToExclusive = dateTo == null ? null : dateTo.plusDays(1);
        long total = mapper.countOrders(
                session.merchantId(), region(), shopId, scopedShopIds, payStatus, refundStatus,
                normalizedOrderNo, dateFrom, dateToExclusive
        );
        List<Map<String, Object>> list = mapper.selectOrders(
                session.merchantId(), region(), shopId, scopedShopIds, payStatus, refundStatus,
                normalizedOrderNo, dateFrom, dateToExclusive,
                normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(this::orderMap).toList();
        return new PageResult<>(
                list,
                total,
                normalizedPage,
                normalizedPageSize,
                (long) normalizedPage * normalizedPageSize < total
        );
    }

    @Transactional
    public Map<String, Object> auditRefund(Long orderId, MerchantRefundAuditRequest request) {
        MerchantSession session = merchant();
        OrderRow order = mapper.selectOrder(orderId, session.merchantId(), region());
        if (order == null) {
            throw new NotFoundException("订单不存在");
        }
        authorizationService.requireShop(session, "order:refund", order.getShopId());
        RefundRow refund = mapper.selectRefund(orderId);
        if (refund == null || refund.getStatus() != 0) {
            throw new IllegalArgumentException("订单没有待处理退款申请");
        }
        String decision = request.decision().trim().toLowerCase();
        String reason = request.reason().trim();
        String action;
        if ("approve".equals(decision)) {
            requireAffected(mapper.approveRefund(orderId, session.operatorId(), reason));
            requireAffected(mapper.markOrderRefunded(orderId));
            mapper.markCouponsRefunded(orderId);
            requireAffected(mapper.restoreDealStock(order.getDealId(), order.getQuantity()));
            action = "refund_approve";
        } else if ("reject".equals(decision)) {
            requireAffected(mapper.rejectRefund(orderId, session.operatorId(), reason));
            action = "refund_reject";
        } else {
            throw new IllegalArgumentException("退款审核决定只允许 approve 或 reject");
        }
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), action, "order", orderId, reason
        );
        return orderMap(requireOrder(orderId, session));
    }

    private void validate(MerchantDealSaveRequest request) {
        if (request.originalPrice().compareTo(request.price()) < 0) {
            throw new IllegalArgumentException("原价不能低于售价");
        }
        if (request.validStart() != null && request.validEnd() != null
                && request.validEnd().isBefore(request.validStart())) {
            throw new IllegalArgumentException("有效期结束日期不能早于开始日期");
        }
        String expectedCurrency = "CN".equals(region()) ? "CNY" : "EUR";
        if (!expectedCurrency.equalsIgnoreCase(request.currency())) {
            throw new IllegalArgumentException("团购币种与当前区域不匹配");
        }
        boolean invalidItem = request.items().stream().anyMatch(item ->
                item.price().compareTo(BigDecimal.ZERO) < 0 || item.quantity() <= 0
        );
        if (invalidItem) {
            throw new IllegalArgumentException("套餐项目数量或价格非法");
        }
    }

    private DealRow toRow(MerchantDealSaveRequest request, MerchantSession session) {
        DealRow row = new DealRow();
        row.setShopId(request.shopId());
        row.setMerchantId(session.merchantId());
        row.setRegion(region());
        row.setType(request.type());
        row.setTitle(request.title().trim());
        row.setCoverImage(request.coverImage().trim());
        row.setPrice(request.price());
        row.setOriginalPrice(request.originalPrice());
        row.setCurrency(request.currency().toUpperCase());
        row.setStock(request.stock());
        row.setValidStart(request.validStart());
        row.setValidEnd(request.validEnd());
        row.setRules(request.rules() == null ? "" : request.rules().trim());
        row.setAuditStatus(0);
        row.setStatus(0);
        return row;
    }

    private void createAuditTask(DealRow row) {
        AuditTaskRow task = new AuditTaskRow();
        task.setBizType(DEAL_AUDIT_BIZ_TYPE);
        task.setBizId(row.getId());
        task.setRegion(region());
        task.setMachineResult(0);
        task.setStatus(0);
        task.setAuditorId(0L);
        task.setRemark("");
        adminAuditMapper.insertAuditTask(task);
    }

    private DealRow requireDeal(Long dealId, MerchantSession session) {
        DealRow row = mapper.selectDeal(dealId, session.merchantId(), region());
        if (row == null) {
            throw new NotFoundException("团购不存在");
        }
        return row;
    }

    private Map<String, Object> dealMap(DealRow row, boolean includeItems) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("shopId", row.getShopId());
        result.put("shopName", row.getShopName());
        result.put("type", row.getType());
        result.put("title", row.getTitle());
        result.put("coverImage", row.getCoverImage());
        result.put("price", row.getPrice());
        result.put("originalPrice", row.getOriginalPrice());
        result.put("currency", row.getCurrency());
        result.put("stock", row.getStock());
        result.put("soldCount", row.getSoldCount());
        result.put("validStart", row.getValidStart());
        result.put("validEnd", row.getValidEnd());
        result.put("rules", row.getRules());
        result.put("auditStatus", row.getAuditStatus());
        result.put("status", row.getStatus());
        if (includeItems) {
            List<DealItemRow> items = mapper.selectDealItems(row.getId());
            result.put("items", items);
        }
        return result;
    }

    private void validateDateRange(LocalDate dateFrom, LocalDate dateTo) {
        if (dateFrom != null && dateTo != null && dateFrom.isAfter(dateTo)) {
            throw new IllegalArgumentException("dateFrom 不能晚于 dateTo");
        }
        if (dateFrom != null && dateTo != null && ChronoUnit.DAYS.between(dateFrom, dateTo) >= 90) {
            throw new IllegalArgumentException("订单查询范围不能超过 90 天");
        }
    }

    private OrderRow requireOrder(Long orderId, MerchantSession session) {
        OrderRow row = mapper.selectOrder(orderId, session.merchantId(), region());
        if (row == null) {
            throw new NotFoundException("订单不存在");
        }
        return row;
    }

    private void requireAffected(int affected) {
        if (affected != 1) {
            throw new IllegalArgumentException("订单或退款状态已变化，请刷新后重试");
        }
    }

    private Map<String, Object> orderMap(OrderRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("orderNo", row.getOrderNo());
        result.put("userId", row.getUserId());
        result.put("dealId", row.getDealId());
        result.put("dealTitle", row.getDealTitle());
        result.put("shopId", row.getShopId());
        result.put("shopName", row.getShopName());
        result.put("coverImage", row.getCoverImage());
        result.put("quantity", row.getQuantity());
        result.put("unitPrice", row.getUnitPrice());
        result.put("amount", row.getAmount());
        result.put("currency", row.getCurrency());
        result.put("payMethod", row.getPayMethod());
        result.put("payStatus", row.getPayStatus());
        result.put("payStatusText", payStatusText(row.getPayStatus()));
        result.put("status", row.getStatus());
        result.put("paidAt", row.getPaidAt());
        result.put("createdAt", row.getCreatedAt());
        RefundRow refund = mapper.selectRefund(row.getId());
        if (refund != null) {
            Map<String, Object> refundMap = new LinkedHashMap<>();
            refundMap.put("id", refund.getId());
            refundMap.put("amount", refund.getAmount());
            refundMap.put("reason", refund.getReason());
            refundMap.put("status", refund.getStatus());
            refundMap.put("statusText", refundStatusText(refund.getStatus()));
            refundMap.put("auditBy", refund.getAuditBy());
            refundMap.put("auditReason", refund.getAuditReason());
            refundMap.put("auditedAt", refund.getAuditedAt());
            refundMap.put("createdAt", refund.getCreatedAt());
            result.put("refund", refundMap);
        }
        return result;
    }

    private String payStatusText(Integer status) {
        return switch (status) {
            case 1 -> "已支付";
            case 2 -> "已退款";
            default -> "待支付";
        };
    }

    private String refundStatusText(Integer status) {
        return switch (status) {
            case 1 -> "退款成功";
            case 2 -> "已驳回";
            default -> "申请中";
        };
    }

    private MerchantSession merchant() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
