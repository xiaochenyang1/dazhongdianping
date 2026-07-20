package com.tuowei.dazhongdianping.module.auth.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.config.PrivacyProperties;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.mapper.UserPrivacyMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.model.GrowthPointsLogRow;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyDeleteTaskRow;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyExportTaskRow;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyTaskQuery;
import com.tuowei.dazhongdianping.module.auth.model.VerificationCodeRow;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyDeleteTaskCreateRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyExportTaskCreateRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyDeleteRuleResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyDeleteTaskResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyExportRuleResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyExportTaskResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.PrivacyOverviewResponse;
import com.tuowei.dazhongdianping.module.browse.model.SearchHistoryRow;
import com.tuowei.dazhongdianping.module.favorite.model.FavoriteRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.CacheControl;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class UserPrivacyService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final TypeReference<List<String>> STRING_LIST_TYPE = new TypeReference<>() {
    };
    private static final Set<String> ALLOWED_EXPORT_MODULES = Set.of(
            "account",
            "orders",
            "reviews",
            "posts",
            "reservations",
            "favorites",
            "follows",
            "messages",
            "circles",
            "topics"
    );
    private static final String DEFAULT_EXPORT_FORMAT = "zip";

    private final AuthCommandMapper authCommandMapper;
    private final UserPrivacyMapper userPrivacyMapper;
    private final PrivacyProperties privacyProperties;
    private final ObjectMapper objectMapper;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private Path exportBaseDir;

    public UserPrivacyService(AuthCommandMapper authCommandMapper,
                              UserPrivacyMapper userPrivacyMapper,
                              PrivacyProperties privacyProperties,
                              ObjectMapper objectMapper) {
        this.authCommandMapper = authCommandMapper;
        this.userPrivacyMapper = userPrivacyMapper;
        this.privacyProperties = privacyProperties;
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void init() {
        exportBaseDir = Path.of(privacyProperties.getExportBaseDir()).toAbsolutePath().normalize();
        try {
            Files.createDirectories(exportBaseDir);
        } catch (IOException exception) {
            throw new IllegalStateException("隐私导出目录初始化失败", exception);
        }
    }

    public PrivacyOverviewResponse overview() {
        Long userId = currentUserId();
        expireReadyExportTasks(userId);
        return new PrivacyOverviewResponse(
                new PrivacyExportRuleResponse(
                        privacyProperties.getExportDailyLimit(),
                        DEFAULT_EXPORT_FORMAT,
                        privacyProperties.getExportExpireHours()
                ),
                new PrivacyDeleteRuleResponse(
                        privacyProperties.getDeleteCoolingOffDays(),
                        true
                ),
                toExportTaskResponse(userPrivacyMapper.selectLatestExportTaskByUserId(userId)),
                toDeleteTaskResponse(userPrivacyMapper.selectLatestDeleteTaskByUserId(userId))
        );
    }

    @Transactional
    public PrivacyExportTaskResponse createExportTask(PrivacyExportTaskCreateRequest request) {
        AppUserRow currentUser = currentUserRow();
        if (userPrivacyMapper.countRecentExportTasks(
                currentUser.getId(),
                LocalDateTime.now().minusHours(24)
        ) >= privacyProperties.getExportDailyLimit()) {
            throw new IllegalArgumentException("今天的隐私导出次数已经用完了");
        }

        List<String> modules = normalizeExportModules(request.getModules());
        String format = normalizeExportFormat(request.getFormat());

        PrivacyExportTaskRow row = new PrivacyExportTaskRow();
        row.setUserId(currentUser.getId());
        row.setScopeJson(writeScopeJson(modules));
        row.setFormat(format);
        row.setStatus(1);
        row.setFileName("");
        row.setFilePath("");
        row.setFailReason("");
        userPrivacyMapper.insertExportTask(row);

        try {
            byte[] payload = buildExportPayload(currentUser, row.getId(), modules, format);
            Path archivePath = writeExportArchive(row.getId(), payload);
            row.setStatus(2);
            row.setFileName(archivePath.getFileName().toString());
            row.setFilePath(archivePath.toString());
            row.setExpireAt(LocalDateTime.now().plusHours(privacyProperties.getExportExpireHours()));
            userPrivacyMapper.updateExportTaskResult(row);
        } catch (Exception exception) {
            userPrivacyMapper.updateExportTaskFailure(row.getId(), summarizeFailureReason(exception));
            throw exception;
        }

        return toExportTaskResponse(userPrivacyMapper.selectExportTaskByIdAndUserId(row.getId(), currentUser.getId()));
    }

    public PageResult<PrivacyExportTaskResponse> listExportTasks(PrivacyTaskQuery query) {
        Long userId = currentUserId();
        expireReadyExportTasks(userId);
        query.normalize();
        query.setUserId(userId);

        long total = userPrivacyMapper.countExportTasks(query);
        List<PrivacyExportTaskResponse> list = userPrivacyMapper.selectExportTasks(query).stream()
                .map(this::toExportTaskResponse)
                .toList();

        return new PageResult<>(
                list,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + list.size() < total
        );
    }

    public PrivacyExportTaskResponse getExportTask(Long taskId) {
        Long userId = currentUserId();
        expireReadyExportTasks(userId);
        return toExportTaskResponse(requireExportTask(taskId, userId));
    }

    public ResponseEntity<Resource> downloadExportTask(Long taskId) {
        Long userId = currentUserId();
        expireReadyExportTasks(userId);
        PrivacyExportTaskRow row = requireExportTask(taskId, userId);
        if (row.getStatus() == null || row.getStatus() != 2) {
            throw new IllegalArgumentException("导出文件当前不可下载");
        }
        if (!StringUtils.hasText(row.getFilePath()) || !StringUtils.hasText(row.getFileName())) {
            throw new NotFoundException("导出文件不存在");
        }

        Path filePath = Path.of(row.getFilePath()).toAbsolutePath().normalize();
        ensureInsideExportDir(filePath);
        if (!Files.exists(filePath) || !Files.isRegularFile(filePath)) {
            throw new NotFoundException("导出文件不存在");
        }

        try {
            Resource resource = new UrlResource(filePath.toUri());
            String contentDisposition = ContentDisposition.attachment()
                    .filename(row.getFileName(), StandardCharsets.UTF_8)
                    .build()
                    .toString();
            return ResponseEntity.ok()
                    .cacheControl(CacheControl.noCache())
                    .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition)
                    .contentType(MediaType.parseMediaType("application/zip"))
                    .body(resource);
        } catch (IOException exception) {
            throw new IllegalStateException("读取隐私导出文件失败", exception);
        }
    }

    @Transactional
    public PrivacyDeleteTaskResponse createDeleteTask(PrivacyDeleteTaskCreateRequest request) {
        AppUserRow currentUser = currentUserRow();
        PrivacyDeleteTaskRow activeTask = userPrivacyMapper.selectActiveDeleteTaskByUserId(currentUser.getId());
        if (activeTask != null) {
            throw new IllegalArgumentException("当前已有删除任务处理中");
        }

        String verifyType = normalizeVerifyType(request.getVerifyType());
        String account = normalizeDeleteAccount(request.getAccount(), currentUser);
        requireDeleteVerification(currentUser, verifyType, account, request);

        PrivacyDeleteTaskRow row = new PrivacyDeleteTaskRow();
        row.setUserId(currentUser.getId());
        row.setVerifyType(verifyType);
        row.setAccountSnapshot(account);
        row.setReason(request.getReason().trim());
        row.setStatus(1);
        row.setCoolingOffExpireAt(LocalDateTime.now().plusDays(privacyProperties.getDeleteCoolingOffDays()));
        userPrivacyMapper.insertDeleteTask(row);

        return toDeleteTaskResponse(userPrivacyMapper.selectDeleteTaskByIdAndUserId(row.getId(), currentUser.getId()));
    }

    @Transactional
    public PrivacyDeleteTaskResponse cancelDeleteTask(Long taskId) {
        PrivacyDeleteTaskRow row = requireDeleteTask(taskId, currentUserId());
        if (row.getStatus() == null || row.getStatus() != 1) {
            throw new IllegalArgumentException("当前删除任务不允许撤销");
        }
        int affected = userPrivacyMapper.cancelDeleteTask(taskId, LocalDateTime.now());
        if (affected != 1) {
            throw new IllegalArgumentException("删除任务撤销失败");
        }
        return toDeleteTaskResponse(requireDeleteTask(taskId, currentUserId()));
    }

    @Transactional
    public void processDueDeleteTasksForUser(Long userId) {
        if (userId == null) {
            return;
        }

        PrivacyDeleteTaskRow dueTask = userPrivacyMapper.selectDueDeleteTaskByUserIdForUpdate(userId);
        if (dueTask == null) {
            return;
        }

        AppUserRow userRow = authCommandMapper.selectUserByIdForUpdate(userId);
        if (userRow != null) {
            String anonymousName = anonymousNickname(userId);
            String email = userRow.getEmail();
            String phone = userRow.getPhone();

            userPrivacyMapper.anonymizeReviews(userId, anonymousName);
            userPrivacyMapper.anonymizeReviewComments(userId, anonymousName);
            userPrivacyMapper.anonymizeReviewReports(userId, anonymousName);
            userPrivacyMapper.anonymizePosts(userId, anonymousName);
            userPrivacyMapper.anonymizePostComments(userId, anonymousName);
            userPrivacyMapper.anonymizePostReports(userId, anonymousName);
            userPrivacyMapper.deleteSearchHistoryByUserId(userId);
            userPrivacyMapper.deleteGrowthPointsLogsByUserId(userId);
            userPrivacyMapper.deleteFollowRelationsByUserId(userId);
            userPrivacyMapper.deleteNotificationsByUserId(userId);
            userPrivacyMapper.anonymizeFollowNotificationsByActor(userId);
            userPrivacyMapper.deleteMessageBlocksByUserId(userId);
            userPrivacyMapper.anonymizeMessagesByUserId(userId);
            userPrivacyMapper.anonymizeMessageReportsByUserId(userId);
            userPrivacyMapper.decrementCircleMemberCountsByUserId(userId);
            userPrivacyMapper.deleteCircleMembershipsByUserId(userId);
            List<Long> followedTopicIds = userPrivacyMapper.selectFollowedTopicIdsByUserId(userId);
            userPrivacyMapper.deleteTopicFollowsByUserId(userId);
            for (Long topicId : followedTopicIds) {
                userPrivacyMapper.refreshTopicFollowerCount(topicId);
            }
            if (StringUtils.hasText(email)) {
                userPrivacyMapper.deleteVerificationCodesByTarget(email);
            }
            if (StringUtils.hasText(phone)) {
                userPrivacyMapper.deleteVerificationCodesByTarget(phone);
            }
            authCommandMapper.revokeUserSessionsByUserId(userId);
            userPrivacyMapper.disableDevicesByUserId(userId);
            userPrivacyMapper.anonymizeUser(userId, anonymousName);
        }

        userPrivacyMapper.completeDeleteTask(dueTask.getId(), LocalDateTime.now());
    }

    private void expireReadyExportTasks(Long userId) {
        userPrivacyMapper.expireReadyExportTasks(userId);
    }

    private PrivacyExportTaskRow requireExportTask(Long taskId, Long userId) {
        PrivacyExportTaskRow row = userPrivacyMapper.selectExportTaskByIdAndUserId(taskId, userId);
        if (row == null) {
            throw new NotFoundException("隐私导出任务不存在");
        }
        return row;
    }

    private PrivacyDeleteTaskRow requireDeleteTask(Long taskId, Long userId) {
        PrivacyDeleteTaskRow row = userPrivacyMapper.selectDeleteTaskByIdAndUserId(taskId, userId);
        if (row == null) {
            throw new NotFoundException("删除任务不存在");
        }
        return row;
    }

    private Long currentUserId() {
        UserSession userSession = UserSessionContext.get();
        if (userSession == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return userSession.userId();
    }

    private AppUserRow currentUserRow() {
        AppUserRow userRow = authCommandMapper.selectUserById(currentUserId());
        if (userRow == null || userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        return userRow;
    }

    private List<String> normalizeExportModules(List<String> modules) {
        List<String> requested = modules == null || modules.isEmpty()
                ? List.copyOf(ALLOWED_EXPORT_MODULES)
                : modules;
        LinkedHashSet<String> normalized = new LinkedHashSet<>();
        for (String module : requested) {
            String value = module == null ? "" : module.trim().toLowerCase(Locale.ROOT);
            if (!ALLOWED_EXPORT_MODULES.contains(value)) {
                throw new IllegalArgumentException("modules 包含不支持的类型");
            }
            normalized.add(value);
        }
        return List.copyOf(normalized);
    }

    private String normalizeExportFormat(String format) {
        if (!StringUtils.hasText(format)) {
            return DEFAULT_EXPORT_FORMAT;
        }
        String value = format.trim().toLowerCase(Locale.ROOT);
        if (!DEFAULT_EXPORT_FORMAT.equals(value)) {
            throw new IllegalArgumentException("当前只支持 zip 导出");
        }
        return value;
    }

    private String normalizeVerifyType(String verifyType) {
        String value = verifyType == null ? "" : verifyType.trim().toLowerCase(Locale.ROOT);
        return switch (value) {
            case "code", "password" -> value;
            default -> throw new IllegalArgumentException("verifyType 不支持");
        };
    }

    private String normalizeDeleteAccount(String account, AppUserRow currentUser) {
        String value = account == null ? "" : account.trim();
        if (!StringUtils.hasText(value)) {
            throw new IllegalArgumentException("account 不能为空");
        }
        if (value.equals(currentUser.getEmail()) || value.equals(currentUser.getPhone())) {
            return value;
        }
        throw new IllegalArgumentException("删除校验账号必须是当前已绑定账号");
    }

    private void requireDeleteVerification(AppUserRow currentUser,
                                           String verifyType,
                                           String account,
                                           PrivacyDeleteTaskCreateRequest request) {
        if ("code".equals(verifyType)) {
            String code = request.getVerifyCode() == null ? "" : request.getVerifyCode().trim();
            if (!StringUtils.hasText(code)) {
                throw new IllegalArgumentException("verifyCode 不能为空");
            }
            int targetType = account.contains("@") ? 1 : 2;
            requireVerificationCode("delete", targetType, account, code);
            return;
        }

        String password = request.getPassword() == null ? "" : request.getPassword().trim();
        if (!StringUtils.hasText(currentUser.getPasswordHash())) {
            throw new IllegalArgumentException("当前账号还没有可校验的登录密码");
        }
        if (!StringUtils.hasText(password) || !passwordEncoder.matches(password, currentUser.getPasswordHash())) {
            throw new IllegalArgumentException("删除校验密码不正确");
        }
    }

    private VerificationCodeRow requireVerificationCode(String scene, int targetType, String target, String code) {
        VerificationCodeRow row = authCommandMapper.selectLatestVerificationCode(scene, targetType, target);
        String codeHash = sha256Hex(code);
        if (row == null
                || row.getStatus() == null
                || row.getStatus() != 0
                || row.getExpireAt() == null
                || !row.getExpireAt().isAfter(LocalDateTime.now())
                || !codeHash.equals(row.getCodeHash())) {
            throw new IllegalArgumentException("验证码无效或已过期");
        }
        int affected = authCommandMapper.markVerificationCodeUsed(row.getId());
        if (affected != 1) {
            throw new IllegalArgumentException("验证码无效或已过期");
        }
        return row;
    }

    private String writeScopeJson(List<String> modules) {
        try {
            return objectMapper.writeValueAsString(modules);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("序列化导出模块失败", exception);
        }
    }

    private byte[] buildExportPayload(AppUserRow currentUser,
                                      Long taskId,
                                      List<String> modules,
                                      String format) {
        Map<String, Object> root = new LinkedHashMap<>();
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("taskId", taskId);
        meta.put("userId", currentUser.getId());
        meta.put("generatedAt", formatDateTime(LocalDateTime.now()));
        meta.put("format", format);
        meta.put("note", "仅导出已真实落地并明确选择的模块；未落地模块不会生成空数据冒充完成。");
        root.put("meta", meta);

        Map<String, Object> moduleData = new LinkedHashMap<>();
        for (String module : modules) {
            moduleData.put(module, switch (module) {
                case "account" -> buildAccountModule(currentUser);
                case "orders" -> buildOrderModule(currentUser.getId());
                case "reviews" -> buildReviewModule(currentUser.getId());
                case "posts" -> buildPostModule(currentUser.getId());
                case "reservations" -> buildReservationModule(currentUser.getId());
                case "favorites" -> buildFavoriteModule(currentUser.getId());
                case "follows" -> buildFollowModule(currentUser.getId());
                case "messages" -> buildMessageModule(currentUser.getId());
                case "circles" -> userPrivacyMapper.selectCirclesForExport(currentUser.getId());
                case "topics" -> userPrivacyMapper.selectTopicsForExport(currentUser.getId());
                default -> List.of();
            });
        }
        root.put("modules", moduleData);

        try {
            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(root);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("生成隐私导出内容失败", exception);
        }
    }

    private Map<String, Object> buildAccountModule(AppUserRow currentUser) {
        Map<String, Object> account = new LinkedHashMap<>();
        account.put("id", currentUser.getId());
        account.put("nickname", currentUser.getNickname());
        account.put("avatar", currentUser.getAvatar());
        account.put("email", currentUser.getEmail());
        account.put("phone", currentUser.getPhone());
        account.put("preferredRegion", currentUser.getPreferredRegion());
        account.put("level", currentUser.getLevel());
        account.put("points", currentUser.getPoints());
        account.put("growthValue", currentUser.getGrowthValue());
        account.put("signature", currentUser.getSignature());
        account.put("growthRecords", userPrivacyMapper.selectGrowthPointsLogsByUserId(currentUser.getId()).stream()
                .map(this::toGrowthRecordExportItem)
                .toList());
        account.put("searchHistory", userPrivacyMapper.selectSearchHistoryByUserId(currentUser.getId()).stream()
                .map(this::toSearchHistoryExportItem)
                .toList());
        return account;
    }

    private List<Map<String, Object>> buildReviewModule(Long userId) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (ReviewRow row : userPrivacyMapper.selectReviewsByUserId(userId)) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", row.getId());
            item.put("shopId", row.getShopId());
            item.put("region", row.getRegion());
            item.put("content", row.getContent());
            item.put("scoreOverall", row.getScoreOverall());
            item.put("scoreTaste", row.getScoreTaste());
            item.put("scoreEnv", row.getScoreEnv());
            item.put("scoreService", row.getScoreService());
            item.put("cost", row.getCost());
            item.put("currency", row.getCurrency());
            item.put("likeCount", row.getLikeCount());
            item.put("commentCount", row.getCommentCount());
            item.put("auditStatus", row.getAuditStatus());
            item.put("auditRemark", row.getAuditRemark());
            item.put("createdAt", formatDateTime(row.getCreatedAt()));
            item.put("updatedAt", formatDateTime(row.getUpdatedAt()));
            items.add(item);
        }
        return items;
    }

    private List<Map<String, Object>> buildPostModule(Long userId) {
        return userPrivacyMapper.selectPostsByUserId(userId).stream().map(row -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", row.getId());
            item.put("region", row.getRegion());
            item.put("title", row.getTitle());
            item.put("content", row.getContent());
            item.put("contentType", row.getContentType());
            item.put("shopId", row.getShopId());
            item.put("dealId", row.getDealId());
            item.put("likeCount", row.getLikeCount());
            item.put("commentCount", row.getCommentCount());
            item.put("auditStatus", row.getAuditStatus());
            item.put("auditRemark", row.getAuditRemark());
            item.put("status", row.getStatus());
            item.put("createdAt", formatDateTime(row.getCreatedAt()));
            item.put("updatedAt", formatDateTime(row.getUpdatedAt()));
            return item;
        }).toList();
    }

    private Map<String, Object> buildFollowModule(Long userId) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("following", userPrivacyMapper.selectFollowingForExport(userId).stream().map(row -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("userId", row.getUserId());
            item.put("nickname", row.getNickname());
            item.put("followedAt", formatDateTime(row.getFollowedAt()));
            return item;
        }).toList());
        result.put("followers", userPrivacyMapper.selectFollowersForExport(userId).stream().map(row -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("userId", row.getUserId());
            item.put("nickname", row.getNickname());
            item.put("followedAt", formatDateTime(row.getFollowedAt()));
            return item;
        }).toList());
        return result;
    }

    private Map<String, Object> buildMessageModule(Long userId) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("conversations", userPrivacyMapper.selectMessageConversationsForExport(userId));
        result.put("messages", userPrivacyMapper.selectMessagesForExport(userId));
        return result;
    }

    private List<Map<String, Object>> buildOrderModule(Long userId) {
        return userPrivacyMapper.selectOrdersByUserId(userId).stream()
                .map(this::toOrderExportItem)
                .toList();
    }

    private Map<String, Object> toOrderExportItem(OrderRow row) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", row.getId());
        item.put("orderNo", row.getOrderNo());
        item.put("dealId", row.getDealId());
        item.put("dealTitle", row.getDealTitle());
        item.put("shopId", row.getShopId());
        item.put("shopName", row.getShopName());
        item.put("region", row.getRegion());
        item.put("quantity", row.getQuantity());
        item.put("unitPrice", row.getUnitPrice());
        item.put("amount", row.getAmount());
        item.put("currency", row.getCurrency());
        item.put("payMethod", row.getPayMethod());
        item.put("payStatus", row.getPayStatus());
        item.put("status", row.getStatus());
        item.put("paidAt", formatDateTime(row.getPaidAt()));
        item.put("expireAt", formatDateTime(row.getExpireAt()));
        item.put("createdAt", formatDateTime(row.getCreatedAt()));
        return item;
    }

    private List<Map<String, Object>> buildReservationModule(Long userId) {
        return userPrivacyMapper.selectReservationsByUserId(userId).stream()
                .map(this::toReservationExportItem)
                .toList();
    }

    private Map<String, Object> toReservationExportItem(ReservationRow row) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", row.getId());
        item.put("reservationNo", row.getReservationNo());
        item.put("shopId", row.getShopId());
        item.put("shopName", row.getShopName());
        item.put("region", row.getRegion());
        item.put("reserveTime", formatDateTime(row.getReserveTime()));
        item.put("peopleCount", row.getPeopleCount());
        item.put("contactName", row.getContactName());
        item.put("contactPhone", row.getContactPhone());
        item.put("remark", row.getRemark());
        item.put("status", row.getStatus());
        item.put("rescheduleCount", row.getRescheduleCount());
        item.put("createdAt", formatDateTime(row.getCreatedAt()));
        return item;
    }

    private List<Map<String, Object>> buildFavoriteModule(Long userId) {
        return userPrivacyMapper.selectFavoritesByUserId(userId).stream()
                .map(this::toFavoriteExportItem)
                .toList();
    }

    private Map<String, Object> toFavoriteExportItem(FavoriteRow row) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", row.getId());
        item.put("targetType", row.getTargetType());
        item.put("targetId", row.getTargetId());
        item.put("targetName", row.getTargetName());
        item.put("coverUrl", row.getCoverUrl());
        item.put("score", row.getScore());
        item.put("pricePerCapita", row.getPricePerCapita());
        item.put("currency", row.getCurrency());
        item.put("address", row.getAddress());
        item.put("cityName", row.getCityName());
        item.put("areaName", row.getAreaName());
        item.put("hasDeal", row.getHasDeal());
        item.put("openNow", row.getOpenNow());
        item.put("tags", row.getTags());
        item.put("createdAt", formatDateTime(row.getCreatedAt()));
        return item;
    }

    private Map<String, Object> toGrowthRecordExportItem(GrowthPointsLogRow row) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", row.getId());
        item.put("type", row.getType());
        item.put("action", row.getAction());
        item.put("bizId", row.getBizId());
        item.put("changeAmount", row.getChangeAmount());
        item.put("balanceAfter", row.getBalanceAfter());
        item.put("remark", row.getRemark());
        item.put("createdAt", formatDateTime(row.getCreatedAt()));
        return item;
    }

    private Map<String, Object> toSearchHistoryExportItem(SearchHistoryRow row) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", row.getId());
        item.put("region", row.getRegion());
        item.put("keyword", row.getKeyword());
        item.put("searchType", row.getSearchType());
        item.put("createdAt", formatDateTime(row.getCreatedAt()));
        item.put("updatedAt", formatDateTime(row.getUpdatedAt()));
        return item;
    }

    private Path writeExportArchive(Long taskId, byte[] payload) {
        String archiveFileName = "privacy-export-%d-%s.zip".formatted(taskId, UUID.randomUUID().toString().replace("-", ""));
        Path target = exportBaseDir.resolve(archiveFileName).normalize();
        ensureInsideExportDir(target);

        try (ZipOutputStream zipOutputStream = new ZipOutputStream(
                Files.newOutputStream(target, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING),
                StandardCharsets.UTF_8)) {
            ZipEntry entry = new ZipEntry("privacy-export-task-%d.json".formatted(taskId));
            zipOutputStream.putNextEntry(entry);
            zipOutputStream.write(payload);
            zipOutputStream.closeEntry();
            return target;
        } catch (IOException exception) {
            throw new IllegalStateException("写入隐私导出文件失败", exception);
        }
    }

    private void ensureInsideExportDir(Path target) {
        if (!target.startsWith(exportBaseDir)) {
            throw new NotFoundException("导出文件不存在");
        }
    }

    private String summarizeFailureReason(Exception exception) {
        String message = exception.getMessage();
        if (!StringUtils.hasText(message)) {
            return "隐私导出任务生成失败";
        }
        return message.length() > 255 ? message.substring(0, 255) : message;
    }

    private String anonymousNickname(Long userId) {
        return "已注销用户" + (userId % 10000);
    }

    private PrivacyExportTaskResponse toExportTaskResponse(PrivacyExportTaskRow row) {
        if (row == null) {
            return null;
        }
        return new PrivacyExportTaskResponse(
                row.getId(),
                row.getStatus(),
                exportStatusText(row.getStatus()),
                readScopes(row.getScopeJson()),
                row.getFormat(),
                row.getStatus() != null && row.getStatus() == 2
                        ? "/api/c/v1/privacy/export-tasks/%d/download".formatted(row.getId())
                        : "",
                formatDateTime(row.getExpireAt()),
                row.getFailReason(),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private PrivacyDeleteTaskResponse toDeleteTaskResponse(PrivacyDeleteTaskRow row) {
        if (row == null) {
            return null;
        }
        return new PrivacyDeleteTaskResponse(
                row.getId(),
                row.getStatus(),
                deleteStatusText(row.getStatus()),
                row.getVerifyType(),
                row.getAccountSnapshot(),
                row.getReason(),
                formatDateTime(row.getCoolingOffExpireAt()),
                formatDateTime(row.getCompletedAt()),
                formatDateTime(row.getCancelledAt()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private List<String> readScopes(String scopeJson) {
        if (!StringUtils.hasText(scopeJson)) {
            return List.of();
        }
        try {
            return objectMapper.readValue(scopeJson, STRING_LIST_TYPE);
        } catch (JsonProcessingException exception) {
            return List.of();
        }
    }

    private String exportStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 0 -> "待处理";
            case 1 -> "处理中";
            case 2 -> "可下载";
            case 3 -> "已过期";
            case 4 -> "失败";
            case 5 -> "已取消";
            default -> "";
        };
    }

    private String deleteStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 0 -> "待确认";
            case 1 -> "冷静期中";
            case 2 -> "处理中";
            case 3 -> "已完成";
            case 4 -> "已取消";
            case 5 -> "已驳回";
            default -> "";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? null : value.format(DATE_TIME_FORMATTER);
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(messageDigest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 不可用", exception);
        }
    }
}
