package com.tuowei.dazhongdianping.module.search.gateway;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocument;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class ElasticsearchShopSearchGatewayTest {

    @Test
    void shouldCreateIndexAndBulkLoadDocuments() {
        SearchProperties properties = new SearchProperties();
        properties.setBaseUrl("http://elasticsearch.test");
        properties.setIndexName("shop_index");
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        ElasticsearchShopSearchGateway gateway = new ElasticsearchShopSearchGateway(
                properties,
                new ObjectMapper(),
                builder
        );
        ShopSearchDocument document = ShopSearchDocument.builder()
                .id(10001L)
                .region("CN")
                .name("渝里火锅徐汇店")
                .namePinyin("yulihuoguoxuhuidian")
                .categoryId(10L)
                .categoryName("火锅")
                .cityId(1L)
                .areaId(101L)
                .latitude(31.195)
                .longitude(121.436)
                .score(new BigDecimal("4.8"))
                .reviewCount(120)
                .pricePerCapita(new BigDecimal("128"))
                .currency("CNY")
                .status(1)
                .tags(List.of("火锅", "川味"))
                .dishNames(List.of("毛肚"))
                .build();

        server.expect(requestTo("http://elasticsearch.test/shop_index"))
                .andExpect(method(HttpMethod.DELETE))
                .andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));
        server.expect(requestTo("http://elasticsearch.test/shop_index"))
                .andExpect(method(HttpMethod.PUT))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("geo_point")))
                .andRespond(withSuccess("{\"acknowledged\":true}", MediaType.APPLICATION_JSON));
        server.expect(requestTo("http://elasticsearch.test/_bulk"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("yulihuoguoxuhuidian")))
                .andRespond(withSuccess("{\"errors\":false}", MediaType.APPLICATION_JSON));

        gateway.rebuildIndex(List.of(document));

        server.verify();
    }

    @Test
    void shouldBuildElasticsearchDslAndMapHits() {
        SearchProperties properties = new SearchProperties();
        properties.setBaseUrl("http://elasticsearch.test");
        properties.setIndexName("shop_index");
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        ElasticsearchShopSearchGateway gateway = new ElasticsearchShopSearchGateway(
                properties,
                new ObjectMapper(),
                builder
        );
        ShopSearchQuery query = new ShopSearchQuery();
        query.setKeyword("huoguo");
        query.setMinScore(new BigDecimal("4.0"));
        query.setHasDeal(true);
        query.setSort("score");

        server.expect(requestTo("http://elasticsearch.test/shop_index/_search"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"fuzziness\":\"AUTO\"")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("namePinyin^2")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"region\":\"CN\"")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("\"score\":{\"gte\":4.0}")))
                .andRespond(withSuccess("""
                        {
                          "hits": {
                            "total": {"value": 1, "relation": "eq"},
                            "hits": [
                              {
                                "_source": {
                                  "id": 10001,
                                  "name": "渝里火锅徐汇店",
                                  "coverUrl": "https://example.com/shop.jpg",
                                  "score": 4.8,
                                  "pricePerCapita": 128.0,
                                  "currency": "CNY",
                                  "address": "徐汇区示例路 88 号",
                                  "areaName": "徐家汇",
                                  "cityName": "上海",
                                  "hasDeal": true,
                                  "openNow": true,
                                  "tags": ["火锅", "川味"]
                                }
                              }
                            ]
                          }
                        }
                        """, MediaType.APPLICATION_JSON));

        PageResult<ShopListItemResponse> result = gateway.search(Region.CN, query);

        assertThat(result.total()).isEqualTo(1);
        assertThat(result.list()).singleElement().satisfies(item -> {
            assertThat(item.id()).isEqualTo(10001L);
            assertThat(item.name()).isEqualTo("渝里火锅徐汇店");
            assertThat(item.currency()).isEqualTo("CNY");
        });
        server.verify();
    }

    @Test
    void shouldUseGeoDistanceSortAndExposeDistanceMeters() {
        SearchProperties properties = new SearchProperties();
        properties.setBaseUrl("http://elasticsearch.test");
        properties.setIndexName("shop_index");
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        ElasticsearchShopSearchGateway gateway = new ElasticsearchShopSearchGateway(
                properties,
                new ObjectMapper(),
                builder
        );
        ShopSearchQuery query = new ShopSearchQuery();
        query.setSort("distance");
        query.setLat(31.2304);
        query.setLng(121.4737);

        server.expect(requestTo("http://elasticsearch.test/shop_index/_search"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("_geo_distance")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("121.4737")))
                .andRespond(withSuccess("""
                        {
                          "hits": {
                            "total": {"value": 1, "relation": "eq"},
                            "hits": [
                              {
                                "sort": [856.4],
                                "_source": {
                                  "id": 10001,
                                  "name": "渝里火锅徐汇店",
                                  "score": 4.8,
                                  "pricePerCapita": 128.0,
                                  "currency": "CNY",
                                  "tags": []
                                }
                              }
                            ]
                          }
                        }
                        """, MediaType.APPLICATION_JSON));

        ShopListItemResponse item = gateway.search(Region.CN, query).list().get(0);

        assertThat(item.distanceMeters()).isEqualTo(856.4);
        server.verify();
    }
}
