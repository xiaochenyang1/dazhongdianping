package com.tuowei.dazhongdianping.module.search.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.search.gateway.ShopSearchGateway;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import java.util.List;
import org.junit.jupiter.api.Test;

class ShopSearchServiceTest {

    @Test
    void shouldRequireCoordinatesForDistanceSort() {
        ShopSearchQuery query = new ShopSearchQuery();
        query.setSort("distance");

        assertThatThrownBy(query::normalize)
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("距离排序必须提供 lat 和 lng");
    }

    @Test
    void shouldUseElasticsearchWhenConfigured() {
        SearchProperties properties = new SearchProperties();
        properties.setProvider(SearchProperties.Provider.ELASTICSEARCH);
        ShopSearchGateway mysqlGateway = mock(ShopSearchGateway.class);
        ShopSearchGateway elasticsearchGateway = mock(ShopSearchGateway.class);
        ShopSearchQuery query = new ShopSearchQuery();
        PageResult<ShopListItemResponse> expected = emptyPage();
        when(elasticsearchGateway.search(Region.CN, query)).thenReturn(expected);

        ShopSearchService service = new ShopSearchService(properties, mysqlGateway, elasticsearchGateway);

        assertThat(service.search(Region.CN, query)).isSameAs(expected);
        verify(elasticsearchGateway).search(Region.CN, query);
    }

    @Test
    void shouldFallbackToMysqlWhenElasticsearchFails() {
        SearchProperties properties = new SearchProperties();
        properties.setProvider(SearchProperties.Provider.ELASTICSEARCH);
        properties.setFallbackOnError(true);
        ShopSearchGateway mysqlGateway = mock(ShopSearchGateway.class);
        ShopSearchGateway elasticsearchGateway = mock(ShopSearchGateway.class);
        ShopSearchQuery query = new ShopSearchQuery();
        PageResult<ShopListItemResponse> expected = emptyPage();
        when(elasticsearchGateway.search(Region.EU, query)).thenThrow(new IllegalStateException("ES unavailable"));
        when(mysqlGateway.search(Region.EU, query)).thenReturn(expected);

        ShopSearchService service = new ShopSearchService(properties, mysqlGateway, elasticsearchGateway);

        assertThat(service.search(Region.EU, query)).isSameAs(expected);
        verify(mysqlGateway).search(Region.EU, query);
    }

    private PageResult<ShopListItemResponse> emptyPage() {
        return new PageResult<>(List.of(), 0, 1, 12, false);
    }
}
