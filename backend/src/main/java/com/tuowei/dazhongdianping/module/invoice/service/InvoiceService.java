package com.tuowei.dazhongdianping.module.invoice.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.invoice.mapper.InvoiceMapper;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceOrderRow;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceRequestRow;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceTitleRow;
import com.tuowei.dazhongdianping.module.invoice.model.TaxRateRow;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceApplyRequest;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceTitleSaveRequest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C 端发票抬头与开票申请。税额 = 订单金额 * rate_bp / 10000。 */
@Service
public class InvoiceService {

    /** 交易订单已支付。 */
    private static final int PAY_STATUS_PAID = 1;

    private final InvoiceMapper mapper;

    public InvoiceService(InvoiceMapper mapper) {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> titles() {
        UserSession user = requireUser();
        return mapper.selectTitles(user.userId(), region()).stream().map(this::titleMap).toList();
    }

    @Transactional
    public Map<String, Object> createTitle(InvoiceTitleSaveRequest request) {
        UserSession user = requireUser();
        String region = region();
        int titleType = request.titleType();
        String taxNo = request.taxNo() == null ? "" : request.taxNo().trim();
        if (titleType == 2 && taxNo.isBlank()) {
            throw new IllegalArgumentException("企业抬头需填写税号");
        }
        boolean isDefault = Boolean.TRUE.equals(request.isDefault());
        if (isDefault) {
            mapper.clearDefaultTitles(user.userId(), region);
        }
        InvoiceTitleRow row = new InvoiceTitleRow();
        row.setUserId(user.userId());
        row.setRegion(region);
        row.setTitleType(titleType);
        row.setName(request.name().trim());
        row.setTaxNo(taxNo);
        row.setEmail(request.email() == null ? "" : request.email().trim());
        row.setIsDefault(isDefault);
        mapper.insertTitle(row);
        return titleMap(mapper.selectTitle(row.getId(), user.userId(), region));
    }

    public PageResult<Map<String, Object>> invoices(Integer page, Integer pageSize) {
        UserSession user = requireUser();
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countUserRequests(user.userId(), region);
        List<Map<String, Object>> list = mapper.selectUserRequests(user.userId(), region, s, (p - 1) * s)
                .stream().map(this::requestMap).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> apply(InvoiceApplyRequest request) {
        UserSession user = requireUser();
        String region = region();
        InvoiceOrderRow order = mapper.selectOrder(request.orderId());
        if (order == null || order.getUserId() == null || !order.getUserId().equals(user.userId())
                || order.getRegion() == null || !order.getRegion().equals(region)) {
            throw new NotFoundException("订单不存在");
        }
        if (order.getPayStatus() == null || order.getPayStatus() != PAY_STATUS_PAID) {
            throw new IllegalArgumentException("订单未支付");
        }
        InvoiceTitleRow title = mapper.selectTitle(request.titleId(), user.userId(), region);
        if (title == null) {
            throw new NotFoundException("发票抬头不存在");
        }
        if (mapper.countByOrder(order.getId()) > 0) {
            throw new ConflictException("该订单已申请开票");
        }
        TaxRateRow rate = mapper.selectEnabledTaxRate(region);
        if (rate == null || rate.getRateBp() == null) {
            throw new IllegalArgumentException("当前区域未配置税率");
        }
        BigDecimal amount = order.getAmount() == null ? BigDecimal.ZERO : order.getAmount();
        InvoiceRequestRow row = new InvoiceRequestRow();
        row.setRegion(region);
        row.setUserId(user.userId());
        row.setOrderId(order.getId());
        row.setTitleId(title.getId());
        row.setAmount(amount.setScale(2, RoundingMode.HALF_UP));
        row.setTaxAmount(amount.multiply(BigDecimal.valueOf(rate.getRateBp()))
                .divide(BigDecimal.valueOf(10000), 2, RoundingMode.HALF_UP));
        row.setCurrency(order.getCurrency() == null ? "" : order.getCurrency());
        try {
            mapper.insertRequest(row);
        } catch (DuplicateKeyException duplicate) {
            throw new ConflictException("该订单已申请开票");
        }
        return requestMap(mapper.selectRequest(row.getId(), region));
    }

    private Map<String, Object> titleMap(InvoiceTitleRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("titleType", row.getTitleType());
        body.put("name", row.getName());
        body.put("taxNo", row.getTaxNo() == null ? "" : row.getTaxNo());
        body.put("email", row.getEmail() == null ? "" : row.getEmail());
        body.put("isDefault", Boolean.TRUE.equals(row.getIsDefault()));
        return body;
    }

    private Map<String, Object> requestMap(InvoiceRequestRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("orderId", row.getOrderId());
        body.put("titleId", row.getTitleId());
        body.put("amount", row.getAmount());
        body.put("taxAmount", row.getTaxAmount());
        body.put("currency", row.getCurrency());
        body.put("status", row.getStatus());
        body.put("statusText", statusText(row.getStatus()));
        body.put("invoiceNo", row.getInvoiceNo() == null ? "" : row.getInvoiceNo());
        body.put("rejectReason", row.getRejectReason() == null ? "" : row.getRejectReason());
        body.put("createdAt", row.getCreatedAt());
        return body;
    }

    private String statusText(Integer status) {
        if (status == null) {
            return "待开票";
        }
        return switch (status) {
            case 2 -> "已开票";
            case 3 -> "已驳回";
            default -> "待开票";
        };
    }

    private UserSession requireUser() {
        UserSession user = UserSessionContext.get();
        if (user == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return user;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
