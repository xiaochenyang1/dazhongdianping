package com.tuowei.dazhongdianping.module.search.service;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import org.junit.jupiter.api.Test;

class ShopSearchIndexEventListenerTest {

    @Test
    void shouldEnqueueChangedShopBeforeTransactionCommit() {
        ShopSearchSyncOutboxService syncOutboxService = mock(ShopSearchSyncOutboxService.class);
        ShopSearchIndexEventListener listener = new ShopSearchIndexEventListener(syncOutboxService);

        listener.onShopChanged(new ShopSearchIndexChangedEvent(10001L));

        verify(syncOutboxService).enqueue(10001L);
    }
}
