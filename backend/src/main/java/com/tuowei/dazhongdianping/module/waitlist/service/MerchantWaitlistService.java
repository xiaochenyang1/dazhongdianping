package com.tuowei.dazhongdianping.module.waitlist.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.waitlist.mapper.WaitlistMapper;
import com.tuowei.dazhongdianping.module.waitlist.model.WaitlistEntryRow;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 商家端叫号台：查看队列、叫号、入座、过号。 */
@Service
public class MerchantWaitlistService {

    private final WaitlistMapper mapper;
    private final WaitlistPresenter presenter;
    private final MerchantAuthorizationService authorizationService;
    private final NotificationService notificationService;

    public MerchantWaitlistService(WaitlistMapper mapper, WaitlistPresenter presenter,
                                   MerchantAuthorizationService authorizationService,
                                   NotificationService notificationService) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.authorizationService = authorizationService;
        this.notificationService = notificationService;
    }

    public List<Map<String, Object>> queue(Long shopId) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "waitlist:view");
        return mapper.selectShopQueue(shopId, session.merchantId(), region()).stream()
                .map(presenter::entry).toList();
    }

    /** 叫号：排队中(1)->已叫号(2)，并通知用户。 */
    @Transactional
    public Map<String, Object> call(Long id) {
        WaitlistEntryRow entry = requireManaged(id);
        String region = region();
        if (mapper.updateStatus(id, entry.getMerchantId(), 2, 1, null, LocalDateTime.now(), null) == 0) {
            throw new ConflictException("当前状态不可叫号");
        }
        notificationService.create(entry.getUserId(), region, "waitlist.called",
                "该叫号啦", "您在「" + safeShop(entry) + "」的排队已叫号，请尽快到店。",
                "/user/waitlist");
        return presenter.entry(mapper.selectMerchantEntry(id, entry.getMerchantId(), region));
    }

    /** 入座：排队中(1)/已叫号(2)->已入座(3)。 */
    @Transactional
    public Map<String, Object> seat(Long id) {
        WaitlistEntryRow entry = requireManaged(id);
        if (mapper.updateStatus(id, entry.getMerchantId(), 3, 1, 2, null, LocalDateTime.now()) == 0) {
            throw new ConflictException("当前状态不可入座");
        }
        return presenter.entry(mapper.selectMerchantEntry(id, entry.getMerchantId(), region()));
    }

    /** 过号：已叫号(2)->已过号(4)。 */
    @Transactional
    public Map<String, Object> pass(Long id) {
        WaitlistEntryRow entry = requireManaged(id);
        if (mapper.updateStatus(id, entry.getMerchantId(), 4, 2, null, null, null) == 0) {
            throw new ConflictException("当前状态不可过号");
        }
        return presenter.entry(mapper.selectMerchantEntry(id, entry.getMerchantId(), region()));
    }

    private WaitlistEntryRow requireManaged(Long id) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "waitlist:manage");
        WaitlistEntryRow entry = mapper.selectMerchantEntry(id, session.merchantId(), region());
        if (entry == null) {
            throw new NotFoundException("排队号不存在");
        }
        return entry;
    }

    private String safeShop(WaitlistEntryRow entry) {
        return entry.getShopName() == null ? "" : entry.getShopName();
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
