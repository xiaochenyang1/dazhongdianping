package com.tuowei.dazhongdianping.module.admin.trade.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.ForbiddenException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.trade.mapper.AdminTradeMapper;
import com.tuowei.dazhongdianping.module.admin.trade.model.ChannelStatementBatchRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.ChannelStatementItemRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.ChannelStatementMatchRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminChannelStatementBatchResponse;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminChannelStatementItemResponse;
import com.tuowei.dazhongdianping.module.admin.trade.service.ChannelStatementCsvParser.StatementRecord;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.MessageDigest;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ChannelStatementService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final long MAX_FILE_BYTES = 5L * 1024L * 1024L;
    private static final Set<String> ALLOWED_CHANNELS = Set.of("stripe");
    private static final Set<String> SUPPORTED_TYPES = Set.of("charge", "payment", "payment_intent", "refund");

    private final AdminTradeMapper mapper;
    private final AdminAuditMapper adminAuditMapper;
    private final ObjectMapper objectMapper;

    public ChannelStatementService(
            AdminTradeMapper mapper,
            AdminAuditMapper adminAuditMapper,
            ObjectMapper objectMapper) {
        this.mapper = mapper;
        this.adminAuditMapper = adminAuditMapper;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public AdminChannelStatementBatchResponse importStatement(
            String channel,
            MultipartFile file,
            String requestIp) {
        AdminSession admin = requireRegionWideAdmin();
        String normalizedChannel = normalizeChannel(channel);
        byte[] content = readFile(file);
        String fileName = normalizeFileName(file.getOriginalFilename());
        String fileSha256 = sha256(content);
        String region = RegionContext.getRegion().name();
        ChannelStatementBatchRow existing = mapper.selectStatementBatchByHash(region, normalizedChannel, fileSha256);
        if (existing != null) {
            throw new ConflictException("该渠道账单文件已经导入，批次 ID=" + existing.getId());
        }

        List<StatementRecord> records = ChannelStatementCsvParser.parse(content);
        ChannelStatementBatchRow batch = new ChannelStatementBatchRow();
        batch.setAdminId(admin.adminId());
        batch.setRegion(region);
        batch.setChannel(normalizedChannel);
        batch.setFileName(fileName);
        batch.setFileSha256(fileSha256);
        batch.setTotalRows(records.size());
        batch.setMatchedRows(0);
        batch.setDiscrepancyRows(0);
        batch.setUnmatchedRows(0);
        batch.setInvalidRows(0);
        batch.setIgnoredRows(0);
        batch.setStatus(0);
        mapper.insertStatementBatch(batch);

        int matched = 0;
        int discrepancy = 0;
        int unmatched = 0;
        int invalid = 0;
        int ignored = 0;
        for (StatementRecord record : records) {
            ChannelStatementItemRow item = reconcile(batch.getId(), normalizedChannel, region, record);
            item.setDiscrepancyReason(limit(item.getDiscrepancyReason(), 255));
            mapper.insertStatementItem(item);
            switch (item.getReconcileStatus()) {
                case "matched" -> matched++;
                case "discrepancy" -> discrepancy++;
                case "unmatched" -> unmatched++;
                case "ignored" -> ignored++;
                default -> invalid++;
            }
        }
        batch.setMatchedRows(matched);
        batch.setDiscrepancyRows(discrepancy);
        batch.setUnmatchedRows(unmatched);
        batch.setInvalidRows(invalid);
        batch.setIgnoredRows(ignored);
        batch.setStatus(1);
        if (mapper.updateStatementBatchSummary(batch) != 1) {
            throw new IllegalStateException("渠道账单批次汇总更新失败");
        }
        adminAuditMapper.insertAuditLog(
                admin.adminId(),
                "trade_statement_import",
                "channel_statement_batch:" + batch.getId(),
                "channel=" + normalizedChannel + ",file=" + fileName + ",total=" + records.size()
                        + ",matched=" + matched + ",discrepancy=" + discrepancy
                        + ",unmatched=" + unmatched + ",invalid=" + invalid + ",ignored=" + ignored,
                StringUtils.hasText(requestIp) ? requestIp.trim() : ""
        );
        return toBatchResponse(mapper.selectStatementBatchById(region, batch.getId()));
    }

    public PageResult<AdminChannelStatementBatchResponse> listBatches(Integer page, Integer pageSize) {
        AdminSession admin = requireAdmin();
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        String region = RegionContext.getRegion().name();
        if (!isRegionWide(admin, region)) {
            return new PageResult<>(List.of(), 0, normalizedPage, normalizedPageSize, false);
        }
        long total = mapper.countStatementBatches(region);
        List<AdminChannelStatementBatchResponse> list = mapper.selectStatementBatches(
                        region, normalizedPageSize, (normalizedPage - 1) * normalizedPageSize).stream()
                .map(this::toBatchResponse)
                .toList();
        return new PageResult<>(
                list, total, normalizedPage, normalizedPageSize,
                (long) normalizedPage * normalizedPageSize < total
        );
    }

    public PageResult<AdminChannelStatementItemResponse> listItems(
            Long batchId,
            String reconcileStatus,
            Integer page,
            Integer pageSize) {
        requireRegionWideAdmin();
        String region = RegionContext.getRegion().name();
        ChannelStatementBatchRow batch = mapper.selectStatementBatchById(region, batchId);
        if (batch == null) {
            throw new NotFoundException("渠道账单批次不存在");
        }
        String normalizedStatus = normalizeReconcileStatus(reconcileStatus);
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 50 : Math.min(200, Math.max(1, pageSize));
        long total = mapper.countStatementItems(batchId, normalizedStatus);
        List<AdminChannelStatementItemResponse> list = mapper.selectStatementItems(
                        batchId, normalizedStatus, normalizedPageSize, (normalizedPage - 1) * normalizedPageSize).stream()
                .map(this::toItemResponse)
                .toList();
        return new PageResult<>(
                list, total, normalizedPage, normalizedPageSize,
                (long) normalizedPage * normalizedPageSize < total
        );
    }

    private ChannelStatementItemRow reconcile(
            Long batchId,
            String channel,
            String region,
            StatementRecord record) {
        ChannelStatementItemRow item = new ChannelStatementItemRow();
        item.setBatchId(batchId);
        item.setLineNo(record.lineNo());
        item.setOrderNo("");
        item.setLocalBizType("");
        item.setLocalBizId(0L);
        item.setLocalCurrency("");
        String type = normalizeTransactionType(record.first("type", "reporting_category", "transaction_type"));
        String transactionId = "refund".equals(type)
                ? record.first("refund_id", "source_id", "transaction_id", "id", "payment_intent_id")
                : record.first("payment_intent_id", "source_id", "transaction_id", "id");
        String importedOrderNo = record.first(
                "order_no", "order_number", "metadata_order_no", "metadata_orderno");
        String rawAmount = record.first("gross", "amount", "transaction_amount");
        String currency = record.first("currency", "transaction_currency").toUpperCase(Locale.ROOT);
        String channelStatus = record.first("status", "transaction_status").toLowerCase(Locale.ROOT);
        item.setTransactionType(limit(type, 32));
        item.setChannelTransactionId(limit(transactionId, 128));
        item.setCurrency(limit(currency, 3));
        item.setChannelStatus(limit(channelStatus, 32));
        item.setOccurredAt(limit(record.first("created_utc", "created", "available_on", "date"), 64));
        item.setOrderNo(limit(importedOrderNo, 32));
        item.setRawData(toJson(Map.of(
                "type", type,
                "channelTransactionId", transactionId,
                "amount", rawAmount,
                "currency", currency,
                "status", channelStatus,
                "occurredAt", item.getOccurredAt(),
                "orderNo", importedOrderNo
        )));

        if (!SUPPORTED_TYPES.contains(type)) {
            item.setReconcileStatus("ignored");
            item.setDiscrepancyReason("该账单行不是支付或退款交易");
            return item;
        }
        if (!StringUtils.hasText(transactionId) && !StringUtils.hasText(importedOrderNo)) {
            item.setReconcileStatus("invalid");
            item.setDiscrepancyReason("缺少渠道交易号和订单号");
            return item;
        }
        BigDecimal amount;
        try {
            amount = new BigDecimal(rawAmount).abs().setScale(2, RoundingMode.HALF_UP);
        } catch (RuntimeException exception) {
            item.setReconcileStatus("invalid");
            item.setDiscrepancyReason("金额格式非法");
            return item;
        }
        item.setAmount(amount);
        if (currency.length() != 3) {
            item.setReconcileStatus("invalid");
            item.setDiscrepancyReason("币种格式非法");
            return item;
        }

        ChannelStatementMatchRow match = StringUtils.hasText(transactionId)
                ? mapper.selectStatementMatch(region, channel, transactionId)
                : null;
        boolean matchedByOrderNo = false;
        if (match == null && StringUtils.hasText(importedOrderNo)) {
            match = mapper.selectStatementMatchByOrderNo(
                    region, channel, importedOrderNo, "refund".equals(type) ? "refund" : "payment");
            matchedByOrderNo = match != null;
        }
        if (match == null) {
            item.setReconcileStatus("unmatched");
            item.setDiscrepancyReason("本地未找到对应支付或退款流水");
            return item;
        }
        item.setOrderNo(match.getOrderNo());
        item.setLocalBizType(match.getBizType());
        item.setLocalBizId(match.getBizId());
        item.setLocalAmount(match.getAmount());
        item.setLocalCurrency(match.getCurrency());
        item.setLocalStatus(match.getStatus());

        if (matchedByOrderNo) {
            item.setReconcileStatus("discrepancy");
            item.setDiscrepancyReason(StringUtils.hasText(transactionId)
                    ? "渠道交易号未匹配，已按订单号找到本地记录"
                    : "账单缺少渠道交易号，已按订单号找到本地记录");
            return item;
        }

        String typeMismatch = transactionTypeMismatch(type, match.getBizType());
        if (typeMismatch != null) {
            item.setReconcileStatus("discrepancy");
            item.setDiscrepancyReason(typeMismatch);
            return item;
        }
        if (match.getAmount() == null || match.getAmount().compareTo(amount) != 0) {
            item.setReconcileStatus("discrepancy");
            item.setDiscrepancyReason("金额不一致：渠道=" + amount + "，本地=" + match.getAmount());
            return item;
        }
        if (match.getCurrency() == null || !match.getCurrency().equalsIgnoreCase(currency)) {
            item.setReconcileStatus("discrepancy");
            item.setDiscrepancyReason("币种不一致：渠道=" + currency + "，本地=" + match.getCurrency());
            return item;
        }
        if (!statusMatches(match.getBizType(), match.getStatus(), channelStatus)) {
            item.setReconcileStatus("discrepancy");
            item.setDiscrepancyReason("状态不一致：渠道=" + channelStatus + "，本地=" + match.getStatus());
            return item;
        }
        item.setReconcileStatus("matched");
        item.setDiscrepancyReason("");
        return item;
    }

    private String transactionTypeMismatch(String statementType, String localType) {
        boolean statementRefund = "refund".equals(statementType);
        boolean localRefund = "refund".equals(localType);
        return statementRefund == localRefund ? null : "交易类型不一致：渠道=" + statementType + "，本地=" + localType;
    }

    private boolean statusMatches(String localType, Integer localStatus, String channelStatus) {
        if (!StringUtils.hasText(channelStatus)) {
            return true;
        }
        if ("payment".equals(localType)) {
            if (Set.of("succeeded", "paid", "available").contains(channelStatus)) {
                return Integer.valueOf(1).equals(localStatus);
            }
            if (Set.of("failed", "canceled", "cancelled").contains(channelStatus)) {
                return Integer.valueOf(2).equals(localStatus);
            }
            return true;
        }
        if (Set.of("succeeded", "paid", "available").contains(channelStatus)) {
            return Integer.valueOf(1).equals(localStatus);
        }
        if (Set.of("failed", "canceled", "cancelled").contains(channelStatus)) {
            return Integer.valueOf(4).equals(localStatus);
        }
        if (Set.of("pending", "processing").contains(channelStatus)) {
            return Integer.valueOf(3).equals(localStatus);
        }
        return true;
    }

    private AdminSession requireAdmin() {
        AdminSession admin = AdminSessionContext.get();
        if (admin == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return admin;
    }

    private AdminSession requireRegionWideAdmin() {
        AdminSession admin = requireAdmin();
        String region = RegionContext.getRegion().name();
        if (!isRegionWide(admin, region)) {
            throw new ForbiddenException("仅区域全量管理员可导入或查看渠道账单");
        }
        return admin;
    }

    private boolean isRegionWide(AdminSession admin, String region) {
        AdminCityScope scope = admin.cityScopes().get(region);
        return scope != null && scope.allCities();
    }

    private byte[] readFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("请选择渠道账单 CSV 文件");
        }
        if (file.getSize() > MAX_FILE_BYTES) {
            throw new IllegalArgumentException("渠道账单 CSV 不能超过 5MB");
        }
        try {
            return file.getBytes();
        } catch (Exception exception) {
            throw new IllegalArgumentException("渠道账单文件读取失败", exception);
        }
    }

    private String normalizeChannel(String channel) {
        String normalized = channel == null ? "" : channel.trim().toLowerCase(Locale.ROOT);
        if (!ALLOWED_CHANNELS.contains(normalized)) {
            throw new IllegalArgumentException("当前仅支持导入 Stripe 渠道账单");
        }
        return normalized;
    }

    private String normalizeFileName(String fileName) {
        String normalized = fileName == null ? "stripe-statement.csv" : fileName.trim();
        if (!normalized.toLowerCase(Locale.ROOT).endsWith(".csv")) {
            throw new IllegalArgumentException("渠道账单文件必须为 CSV 格式");
        }
        return limit(normalized.replace('\\', '_').replace('/', '_'), 255);
    }

    private String normalizeTransactionType(String value) {
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        if (normalized.contains("refund")) {
            return "refund";
        }
        if (normalized.contains("payment_intent")) {
            return "payment_intent";
        }
        if (normalized.contains("charge")) {
            return "charge";
        }
        if (normalized.contains("payment")) {
            return "payment";
        }
        return normalized;
    }

    private String normalizeReconcileStatus(String status) {
        String normalized = status == null ? "" : status.trim().toLowerCase(Locale.ROOT);
        if (normalized.isBlank()) {
            return null;
        }
        if (!Set.of("matched", "discrepancy", "unmatched", "invalid", "ignored").contains(normalized)) {
            throw new IllegalArgumentException("账单核对状态不合法");
        }
        return normalized;
    }

    private String sha256(byte[] content) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(content));
        } catch (Exception exception) {
            throw new IllegalStateException("渠道账单摘要计算失败", exception);
        }
    }

    private String toJson(Map<String, String> values) {
        try {
            return objectMapper.writeValueAsString(values);
        } catch (JsonProcessingException exception) {
            return "{}";
        }
    }

    private AdminChannelStatementBatchResponse toBatchResponse(ChannelStatementBatchRow row) {
        return new AdminChannelStatementBatchResponse(
                row.getId(), row.getChannel(), row.getFileName(), row.getFileSha256(),
                row.getTotalRows(), row.getMatchedRows(), row.getDiscrepancyRows(), row.getUnmatchedRows(),
                row.getInvalidRows(), row.getIgnoredRows(), row.getStatus(),
                Integer.valueOf(1).equals(row.getStatus()) ? "已完成" : "处理中",
                row.getCreatedAt() == null ? "" : row.getCreatedAt().format(DATE_TIME_FORMATTER)
        );
    }

    private AdminChannelStatementItemResponse toItemResponse(ChannelStatementItemRow row) {
        return new AdminChannelStatementItemResponse(
                row.getId(), row.getLineNo(), row.getTransactionType(), row.getChannelTransactionId(),
                row.getAmount(), row.getCurrency(), row.getChannelStatus(), row.getOccurredAt(), row.getOrderNo(),
                row.getLocalBizType(), row.getLocalBizId(), row.getLocalAmount(), row.getLocalCurrency(),
                row.getLocalStatus(), row.getReconcileStatus(), reconcileStatusText(row.getReconcileStatus()),
                row.getDiscrepancyReason()
        );
    }

    private String reconcileStatusText(String status) {
        return switch (status == null ? "" : status) {
            case "matched" -> "已匹配";
            case "discrepancy" -> "存在差异";
            case "unmatched" -> "本地缺失";
            case "ignored" -> "已忽略";
            default -> "无效行";
        };
    }

    private String limit(String value, int maxLength) {
        if (value == null) {
            return "";
        }
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }
}
