package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class ShopSearchIndexEventListener {

    private final ShopSearchSyncOutboxService syncOutboxService;

    public ShopSearchIndexEventListener(ShopSearchSyncOutboxService syncOutboxService) {
        this.syncOutboxService = syncOutboxService;
    }

    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT, fallbackExecution = true)
    public void onShopChanged(ShopSearchIndexChangedEvent event) {
        syncOutboxService.enqueue(event.shopId());
    }
}
