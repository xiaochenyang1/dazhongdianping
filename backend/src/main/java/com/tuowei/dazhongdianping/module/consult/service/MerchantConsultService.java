package com.tuowei.dazhongdianping.module.consult.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.consult.mapper.ConsultMapper;
import com.tuowei.dazhongdianping.module.consult.model.ConsultMessageRow;
import com.tuowei.dazhongdianping.module.consult.model.ConsultSessionRow;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultMessageRequest;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import java.time.LocalDateTime;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Isolation;

/** 商家端在线咨询：客服会话列表、消息收发。 */
@Service
public class MerchantConsultService {

    private static final String CONSULT_REPLY_TYPE = "consult.reply";

    private final ConsultMapper mapper;
    private final ConsultPresenter presenter;
    private final ConsultMessageReader reader;
    private final MerchantAuthorizationService authorizationService;
    private final NotificationService notificationService;

    public MerchantConsultService(ConsultMapper mapper, ConsultPresenter presenter,
                                  MerchantAuthorizationService authorizationService,
                                  NotificationService notificationService, ConsultMessageReader reader) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.reader = reader;
        this.authorizationService = authorizationService;
        this.notificationService = notificationService;
    }

    public Map<String, Object> sessions(LocalDateTime beforeUpdatedAt, Long beforeId, Integer pageSize, boolean unreadOnly) {
        int size = ConsultSessionPage.validate(beforeUpdatedAt, beforeId, pageSize);
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "consult:view");
        return ConsultSessionPage.present(mapper.selectMerchantSessions(session.merchantId(), region(), authorizationService.scopedShopIds(session), beforeUpdatedAt, beforeId, unreadOnly, size + 1), size, 2, presenter);
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Map<String, Object> messages(Long sessionId, Long beforeId, Long afterId, Integer pageSize) {
        int size = ConsultMessageReader.pageSize(beforeId, afterId, pageSize);
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "consult:view");
        mapper.lockSession(sessionId);
        ConsultSessionRow s = mapper.selectMerchantSession(sessionId, session.merchantId(), region());
        if (s == null) {
            throw new NotFoundException("会话不存在");
        }
        authorizationService.requireShop(session, "consult:view", s.getShopId());
        return reader.read(s, 2, beforeId, afterId, size);
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public Map<String, Object> send(Long sessionId, ConsultMessageRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "consult:reply");
        String region = region();
        mapper.lockSession(sessionId);
        ConsultSessionRow s = mapper.selectMerchantSession(sessionId, session.merchantId(), region);
        if (s == null) {
            throw new NotFoundException("会话不存在");
        }
        authorizationService.requireShop(session, "consult:reply", s.getShopId());
        String content = req.content().trim();
        ConsultMessageRow msg = new ConsultMessageRow();
        msg.setSessionId(sessionId);
        msg.setRegion(region);
        msg.setSenderType(2);
        msg.setSenderId(session.operatorId());
        msg.setContent(content);
        mapper.insertMessage(msg);
        // 商家回复：用户侧未读 +1，并推送通知。
        mapper.updateSessionOnMessage(sessionId, content, LocalDateTime.now(), 1, 0);
        notificationService.create(s.getUserId(), region, CONSULT_REPLY_TYPE,
                "商家回复了你的咨询", content, "/user/consult/" + sessionId);
        return presenter.message(msg);
    }

    private MerchantSession requireSession() {
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
