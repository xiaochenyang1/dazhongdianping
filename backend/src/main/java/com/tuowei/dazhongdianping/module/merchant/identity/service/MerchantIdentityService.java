package com.tuowei.dazhongdianping.module.merchant.identity.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.service.MerchantAuthService;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantApplicationRow;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantOperatorRow;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantRegistrationRow;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantRegisterRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantSettlementApplyRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantIdentityService {

    private static final long OWNER_ROLE_ID = 1L;

    private final MerchantIdentityMapper mapper;
    private final MerchantAuthService authService;
    private final ObjectMapper objectMapper;
    private final PasswordEncoder passwordEncoder;

    public MerchantIdentityService(
            MerchantIdentityMapper mapper,
            MerchantAuthService authService,
            ObjectMapper objectMapper
    ) {
        this.mapper = mapper;
        this.authService = authService;
        this.objectMapper = objectMapper;
        this.passwordEncoder = new BCryptPasswordEncoder();
    }

    @Transactional
    public Map<String, Object> register(MerchantRegisterRequest request) {
        String account = normalizeAccount(request.account());
        if (mapper.selectOperatorByAccount(account) != null) {
            throw new IllegalArgumentException("商户账号已存在");
        }

        MerchantRegistrationRow merchant = new MerchantRegistrationRow();
        merchant.setAccount(account);
        merchant.setCompanyName(request.companyName().trim());
        merchant.setContactName(request.contactName().trim());
        merchant.setContactPhone(request.contactPhone().trim());
        merchant.setRegion(request.region());
        merchant.setAuditStatus(0);
        merchant.setStatus(1);
        mapper.insertMerchant(merchant);

        MerchantOperatorRow operator = new MerchantOperatorRow();
        operator.setMerchantId(merchant.getId());
        operator.setAccount(account);
        operator.setPasswordHash(passwordEncoder.encode(request.password()));
        operator.setName(request.contactName().trim());
        operator.setPhone(request.contactPhone().trim());
        operator.setEmail(account.contains("@") ? account : "");
        operator.setOperatorType(1);
        operator.setShopScopeType(1);
        operator.setOperatorStatus(1);
        mapper.insertOperator(operator);
        mapper.insertOperatorRole(operator.getId(), OWNER_ROLE_ID);

        MerchantAuthService.MerchantLoginResult login = authService.issueSession(new MerchantSession(
                operator.getId(), merchant.getId(), account, 1
        ));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("accessToken", login.accessToken());
        result.put("tokenType", "Bearer");
        result.put("merchantId", merchant.getId());
        result.put("operatorId", operator.getId());
        result.put("account", account);
        result.put("auditStatus", 0);
        return result;
    }

    @Transactional
    public Map<String, Object> apply(MerchantSettlementApplyRequest request) {
        MerchantSession session = merchant();
        MerchantApplicationRow application = mapper.selectApplication(session.merchantId());
        String photoJson = writePhotoJson(request.shopPhotoUrls());
        if (application == null) {
            mapper.insertApplication(
                    session.merchantId(),
                    request.licenseUrl().trim(),
                    request.legalPerson().trim(),
                    photoJson
            );
        } else {
            mapper.updateApplication(
                    session.merchantId(),
                    request.licenseUrl().trim(),
                    request.legalPerson().trim(),
                    photoJson
            );
        }
        mapper.updateMerchantAuditStatus(session.merchantId(), 0);
        return applicationMap(requireApplication(session.merchantId()));
    }

    public Map<String, Object> status() {
        MerchantSession session = merchant();
        MerchantApplicationRow application = mapper.selectApplication(session.merchantId());
        if (application == null) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("merchantId", session.merchantId());
            result.put("status", -1);
            result.put("statusText", "未提交");
            result.put("shopPhotoUrls", List.of());
            return result;
        }
        return applicationMap(application);
    }

    private MerchantApplicationRow requireApplication(Long merchantId) {
        MerchantApplicationRow application = mapper.selectApplication(merchantId);
        if (application == null) {
            throw new NotFoundException("商户资质申请不存在");
        }
        return application;
    }

    private Map<String, Object> applicationMap(MerchantApplicationRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("merchantId", row.getMerchantId());
        result.put("licenseUrl", row.getLicenseUrl());
        result.put("legalPerson", row.getLegalPerson());
        result.put("shopPhotoUrls", readPhotoJson(row.getShopPhotoUrls()));
        result.put("status", row.getStatus());
        result.put("statusText", switch (row.getStatus()) {
            case 1 -> "已通过";
            case 2 -> "已驳回";
            default -> "待审核";
        });
        result.put("rejectReason", row.getRejectReason());
        result.put("submittedAt", row.getSubmittedAt());
        result.put("auditedAt", row.getAuditedAt());
        return result;
    }

    private String writePhotoJson(List<String> urls) {
        try {
            return objectMapper.writeValueAsString(urls.stream().map(String::trim).toList());
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException("门店照片数据不合法");
        }
    }

    private List<String> readPhotoJson(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<>() {
            });
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("商户资质照片数据损坏", exception);
        }
    }

    private MerchantSession merchant() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }

    private String normalizeAccount(String account) {
        return account.trim().toLowerCase(Locale.ROOT);
    }
}
