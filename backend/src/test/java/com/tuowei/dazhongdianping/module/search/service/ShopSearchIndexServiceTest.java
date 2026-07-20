package com.tuowei.dazhongdianping.module.search.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.search.gateway.ShopSearchIndexGateway;
import com.tuowei.dazhongdianping.module.search.mapper.SearchIndexMapper;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocument;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocumentRow;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class ShopSearchIndexServiceTest {

    @SuppressWarnings({"rawtypes", "unchecked"})
    @Test
    void shouldBuildDocumentsFromMysqlAndRebuildElasticsearchIndex() {
        SearchProperties properties = new SearchProperties();
        properties.setProvider(SearchProperties.Provider.ELASTICSEARCH);
        SearchIndexMapper mapper = mock(SearchIndexMapper.class);
        ShopSearchIndexGateway gateway = mock(ShopSearchIndexGateway.class);
        ShopSearchDocumentRow row = new ShopSearchDocumentRow();
        row.setId(10001L);
        row.setRegion("CN");
        row.setName("渝里火锅徐汇店");
        row.setCategoryId(10L);
        row.setCategoryName("火锅");
        row.setCityId(1L);
        row.setCityName("上海");
        row.setAreaId(101L);
        row.setAreaName("徐家汇");
        row.setLatitude(31.195);
        row.setLongitude(121.436);
        row.setScore(new BigDecimal("4.8"));
        row.setReviewCount(120);
        row.setPricePerCapita(new BigDecimal("128"));
        row.setCurrency("CNY");
        row.setStatus(1);
        row.setTags("火锅,川味");
        when(mapper.selectActiveShops()).thenReturn(List.of(row));
        when(mapper.selectDishNames(10001L)).thenReturn(List.of("毛肚", "虾滑"));
        ShopSearchIndexService service = new ShopSearchIndexService(
                properties,
                mapper,
                gateway,
                new ShopNamePinyinConverter()
        );

        int count = service.rebuildAll();

        assertThat(count).isEqualTo(1);
        ArgumentCaptor<List<ShopSearchDocument>> captor = ArgumentCaptor.forClass(List.class);
        verify(gateway).rebuildIndex(captor.capture());
        assertThat(captor.getValue()).singleElement().satisfies(document -> {
            assertThat(document.getNamePinyin()).isEqualTo("yulihuoguoxuhuidian");
            assertThat(document.getDishNames()).containsExactly("毛肚", "虾滑");
            assertThat(document.getTags()).containsExactly("火锅", "川味");
            assertThat(document.getLatitude()).isEqualTo(31.195);
        });
    }

    @Test
    void shouldDeleteIndexDocumentWhenShopIsNoLongerActive() {
        SearchProperties properties = new SearchProperties();
        properties.setProvider(SearchProperties.Provider.ELASTICSEARCH);
        SearchIndexMapper mapper = mock(SearchIndexMapper.class);
        ShopSearchIndexGateway gateway = mock(ShopSearchIndexGateway.class);
        when(mapper.selectActiveShop(10001L)).thenReturn(null);
        ShopSearchIndexService service = new ShopSearchIndexService(
                properties,
                mapper,
                gateway,
                new ShopNamePinyinConverter()
        );

        service.syncShop(10001L);

        verify(gateway).deleteDocument(10001L);
    }
}
