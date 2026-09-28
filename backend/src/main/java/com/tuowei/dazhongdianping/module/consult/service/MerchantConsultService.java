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
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 商家端在线咨询：客服会话列表、消息收发。 */
@Service
public class MerchantConsultService {

    private static final String CONSULT_REPLY_TYPE = "consult.reply";

    private final ConsultMapper mapper;
    private final ConsultPresenter presenter;
    private final MerchantAuthorizationService authorizationService;
    private final NotificationService notificationService;

    public MerchantConsultService(ConsultMapper mapper, ConsultPresenter presenter,
                                  MerchantAuthorizationService authorizationService,
                                  NotificationService notificationService) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.authorizationService = authorizationService;
        this.notificationService = notificationService;
    }

    public List<Map<String, Object>> sessions() {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "consult:view");
        return presenter.sessions(mapper.selectMerchantSessions(session.merchantId(), region()), 2);
    }

    @Transactional
    public Map<String, Object> messages(Long sessionId) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "consult:view");
        ConsultSessionRow s = mapper.selectMerchantSession(sessionId, session.merchantId(), region());
        if (s == null) {
            throw new NotFoundException("会话不存在");
        }
        mapper.markMerchantRead(sessionId);
        s.setMerchantUnread(0);
        return Map.of(
                "session", presenter.session(s, 2),
                "messages", presenter.messages(mapper.selectMessages(sessionId)));
    }

    @Transactional
    public Map<String, Object> send(Long sessionId, ConsultMessageRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "consult:reply");
        String region = region();
        ConsultSessionRow s = mapper.selectMerchantSession(sessionId, session.merchantId(), region);
        if (s == null) {
            throw new NotFoundException("会话不存在");
        }
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
