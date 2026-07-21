package com.tuowei.dazhongdianping.module.admin.geodata;

import static org.assertj.core.api.Assertions.assertThat;

import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.event.ApplicationEvents;
import org.springframework.test.context.event.RecordApplicationEvents;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@RecordApplicationEvents
class AdminGeoDataSearchIndexEventTest {

    @Autowired
    private AdminGeoDataService geoDataService;

    @Autowired
    private ApplicationEvents applicationEvents;

    @Test
    void shouldRefreshReferencedShopIndexAfterGeoStatusChanges() {
        RegionContext.setRegion(Region.EU);
        try {
            geoDataService.updateCategoryStatus(202L, 0);
            geoDataService.updateCityStatus(102L, 0);
            geoDataService.updateAreaStatus(1021L, 0);

            assertThat(applicationEvents.stream(ShopSearchIndexChangedEvent.class)
                    .map(ShopSearchIndexChangedEvent::shopId)
                    .filter(shopId -> shopId.equals(20002L)))
                    .hasSize(3);
        } finally {
            RegionContext.clear();
        }
    }
}
