package com.tuowei.dazhongdianping.module.search.service;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import org.junit.jupiter.api.Test;

class ShopSearchIndexEventListenerTest {

    @Test
    void shouldSyncChangedShopAfterTransactionCommit() {
        ShopSearchIndexService indexService = mock(ShopSearchIndexService.class);
        ShopSearchIndexEventListener listener = new ShopSearchIndexEventListener(indexService);

        listener.onShopChanged(new ShopSearchIndexChangedEvent(10001L));

        verify(indexService).syncShop(10001L);
    }
}
