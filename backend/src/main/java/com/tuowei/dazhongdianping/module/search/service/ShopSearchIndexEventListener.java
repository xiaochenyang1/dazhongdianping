package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class ShopSearchIndexEventListener {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShopSearchIndexEventListener.class);

    private final ShopSearchIndexService shopSearchIndexService;

    public ShopSearchIndexEventListener(ShopSearchIndexService shopSearchIndexService) {
        this.shopSearchIndexService = shopSearchIndexService;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onShopChanged(ShopSearchIndexChangedEvent event) {
        try {
            shopSearchIndexService.syncShop(event.shopId());
        } catch (RuntimeException exception) {
            LOGGER.error("Failed to sync shop {} to Elasticsearch; run admin reindex to recover", event.shopId(), exception);
        }
    }
}
