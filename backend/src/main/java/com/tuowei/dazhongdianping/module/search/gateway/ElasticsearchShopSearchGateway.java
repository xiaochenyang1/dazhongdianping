package com.tuowei.dazhongdianping.module.search.gateway;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocument;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Component("elasticsearchShopSearchGateway")
public class ElasticsearchShopSearchGateway implements ShopSearchGateway, ShopSearchIndexGateway {

    private static final String INDEX_NOT_FOUND_ERROR = "index_not_found_exception";
    private static final String INDEX_ALREADY_EXISTS_ERROR = "resource_already_exists_exception";

    private final SearchProperties searchProperties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final Object indexInitializationMonitor = new Object();
    private volatile boolean indexKnownPresent;

    public ElasticsearchShopSearchGateway(SearchProperties searchProperties,
                                           ObjectMapper objectMapper,
                                           RestClient.Builder restClientBuilder) {
        this.searchProperties = searchProperties;
        this.objectMapper = objectMapper;
        this.restClient = restClientBuilder.baseUrl(searchProperties.getBaseUrl()).build();
    }

    @Override
    public PageResult<ShopListItemResponse> search(Region region, ShopSearchQuery query) {
        query.normalize();
        try {
            PageResult<ShopListItemResponse> result = executeSearch(region, query);
            indexKnownPresent = true;
            return result;
        } catch (RuntimeException exception) {
            if (isElasticsearchError(exception, 404, INDEX_NOT_FOUND_ERROR)) {
                indexKnownPresent = false;
                try {
                    ensureIndexExists();
                    return emptyPage(query);
                } catch (RuntimeException initializationException) {
                    throw new IllegalStateException("Elasticsearch 商户搜索失败", initializationException);
                }
            }
            throw new IllegalStateException("Elasticsearch 商户搜索失败", exception);
        }
    }

    @Override
    public void rebuildIndex(List<ShopSearchDocument> documents) {
        synchronized (indexInitializationMonitor) {
            try {
                restClient.delete()
                        .uri("/{index}", searchProperties.getIndexName())
                        .exchange((request, response) -> null);
                indexKnownPresent = false;
                createIndex();
                indexKnownPresent = true;
                if (!documents.isEmpty()) {
                    String response = restClient.post()
                            .uri(uriBuilder -> uriBuilder
                                    .path("/_bulk")
                                    .queryParam("refresh", "wait_for")
                                    .build())
                            .contentType(MediaType.parseMediaType("application/x-ndjson"))
                            .body(bulkBody(documents))
                            .retrieve()
                            .body(String.class);
                    if (objectMapper.readTree(response == null ? "{}" : response).path("errors").asBoolean(false)) {
                        throw new IllegalStateException("Elasticsearch 批量索引包含失败项");
                    }
                }
            } catch (Exception exception) {
                indexKnownPresent = false;
                throw new IllegalStateException("重建 Elasticsearch 商户索引失败", exception);
            }
        }
    }

    @Override
    public void indexDocument(ShopSearchDocument document) {
        try {
            restClient.put()
                    .uri("/{index}/_doc/{id}", searchProperties.getIndexName(), document.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(toIndexSource(document))
                    .retrieve()
                    .toBodilessEntity();
        } catch (RuntimeException exception) {
            throw new IllegalStateException("写入 Elasticsearch 商户索引失败", exception);
        }
    }

    @Override
    public void deleteDocument(Long shopId) {
        try {
            restClient.delete()
                    .uri("/{index}/_doc/{id}", searchProperties.getIndexName(), shopId)
                    .retrieve()
                    .onStatus(status -> status.value() == 404, (request, response) -> {
                    })
                    .toBodilessEntity();
        } catch (RuntimeException exception) {
            throw new IllegalStateException("删除 Elasticsearch 商户索引失败", exception);
        }
    }

    private PageResult<ShopListItemResponse> executeSearch(Region region, ShopSearchQuery query) {
        String responseBody = restClient.post()
                .uri("/{index}/_search", searchProperties.getIndexName())
                .contentType(MediaType.APPLICATION_JSON)
                .body(buildSearchBody(region, query))
                .retrieve()
                .body(String.class);
        return mapSearchResponse(responseBody, query);
    }

    private void ensureIndexExists() {
        synchronized (indexInitializationMonitor) {
            if (indexKnownPresent) {
                return;
            }
            try {
                createIndex();
            } catch (RuntimeException exception) {
                if (!isElasticsearchError(exception, 400, INDEX_ALREADY_EXISTS_ERROR)) {
                    throw exception;
                }
            }
            indexKnownPresent = true;
        }
    }

    private void createIndex() {
        restClient.put()
                .uri("/{index}", searchProperties.getIndexName())
                .contentType(MediaType.APPLICATION_JSON)
                .body(indexDefinition())
                .retrieve()
                .toBodilessEntity();
    }

    private boolean isElasticsearchError(Throwable exception, int statusCode, String errorType) {
        Throwable candidate = exception;
        while (candidate != null) {
            if (candidate instanceof RestClientResponseException responseException
                    && responseException.getStatusCode().value() == statusCode
                    && responseContainsErrorType(responseException.getResponseBodyAsString(), errorType)) {
                return true;
            }
            candidate = candidate.getCause();
        }
        return false;
    }

    private boolean responseContainsErrorType(String responseBody, String errorType) {
        try {
            JsonNode error = objectMapper.readTree(responseBody == null ? "{}" : responseBody).path("error");
            if (errorType.equals(error.path("type").asText())) {
                return true;
            }
            for (JsonNode rootCause : error.path("root_cause")) {
                if (errorType.equals(rootCause.path("type").asText())) {
                    return true;
                }
            }
            return false;
        } catch (Exception ignored) {
            return false;
        }
    }

    private PageResult<ShopListItemResponse> emptyPage(ShopSearchQuery query) {
        return new PageResult<>(List.of(), 0, query.getPage(), query.getPageSize(), false);
    }

    private Map<String, Object> indexDefinition() {
        Map<String, Object> pinyinPrefixFilter = Map.of(
                "type", "edge_ngram",
                "min_gram", 2,
                "max_gram", 64
        );
        Map<String, Object> pinyinPrefixAnalyzer = Map.of(
                "type", "custom",
                "tokenizer", "keyword",
                "filter", List.of("lowercase", "pinyin_prefix_filter")
        );
        Map<String, Object> pinyinSearchAnalyzer = Map.of(
                "type", "custom",
                "tokenizer", "keyword",
                "filter", List.of("lowercase")
        );
        Map<String, Object> settings = Map.of(
                "index", Map.of("max_ngram_diff", 62),
                "analysis", Map.of(
                        "filter", Map.of("pinyin_prefix_filter", pinyinPrefixFilter),
                        "analyzer", Map.of(
                                "pinyin_prefix_analyzer", pinyinPrefixAnalyzer,
                                "pinyin_search_analyzer", pinyinSearchAnalyzer
                        )
                )
        );
        Map<String, Object> properties = new LinkedHashMap<>();
        properties.put("id", Map.of("type", "long"));
        properties.put("region", Map.of("type", "keyword"));
        properties.put("name", Map.of("type", "text"));
        properties.put("namePinyin", Map.of(
                "type", "text",
                "analyzer", "pinyin_prefix_analyzer",
                "search_analyzer", "pinyin_search_analyzer"
        ));
        properties.put("categoryId", Map.of("type", "long"));
        properties.put("categoryName", Map.of("type", "text", "fields", Map.of("keyword", Map.of("type", "keyword"))));
        properties.put("cityId", Map.of("type", "long"));
        properties.put("cityName", Map.of("type", "keyword"));
        properties.put("areaId", Map.of("type", "long"));
        properties.put("areaName", Map.of("type", "keyword"));
        properties.put("location", Map.of("type", "geo_point"));
        properties.put("score", Map.of("type", "double"));
        properties.put("reviewCount", Map.of("type", "integer"));
        properties.put("pricePerCapita", Map.of("type", "double"));
        properties.put("currency", Map.of("type", "keyword"));
        properties.put("tags", Map.of("type", "keyword"));
        properties.put("dishNames", Map.of("type", "text"));
        properties.put("hasDeal", Map.of("type", "boolean"));
        properties.put("openNow", Map.of("type", "boolean"));
        properties.put("status", Map.of("type", "integer"));
        return Map.of(
                "settings", settings,
                "mappings", Map.of("properties", properties)
        );
    }

    private String bulkBody(List<ShopSearchDocument> documents) throws Exception {
        StringBuilder body = new StringBuilder();
        for (ShopSearchDocument document : documents) {
            body.append(objectMapper.writeValueAsString(Map.of(
                    "index", Map.of("_index", searchProperties.getIndexName(), "_id", document.getId())
            ))).append('\n');
            body.append(objectMapper.writeValueAsString(toIndexSource(document))).append('\n');
        }
        return body.toString();
    }

    private Map<String, Object> toIndexSource(ShopSearchDocument document) {
        Map<String, Object> source = new LinkedHashMap<>();
        putIfNotNull(source, "id", document.getId());
        putIfNotNull(source, "region", document.getRegion());
        putIfNotNull(source, "name", document.getName());
        putIfNotNull(source, "namePinyin", document.getNamePinyin());
        putIfNotNull(source, "categoryId", document.getCategoryId());
        putIfNotNull(source, "categoryName", document.getCategoryName());
        putIfNotNull(source, "cityId", document.getCityId());
        putIfNotNull(source, "cityName", document.getCityName());
        putIfNotNull(source, "areaId", document.getAreaId());
        putIfNotNull(source, "areaName", document.getAreaName());
        if (document.getLatitude() != null && document.getLongitude() != null) {
            source.put("location", Map.of("lat", document.getLatitude(), "lon", document.getLongitude()));
        }
        putIfNotNull(source, "coverUrl", document.getCoverUrl());
        putIfNotNull(source, "score", document.getScore());
        putIfNotNull(source, "reviewCount", document.getReviewCount());
        putIfNotNull(source, "pricePerCapita", document.getPricePerCapita());
        putIfNotNull(source, "currency", document.getCurrency());
        putIfNotNull(source, "address", document.getAddress());
        putIfNotNull(source, "hasDeal", document.getHasDeal());
        putIfNotNull(source, "openNow", document.getOpenNow());
        putIfNotNull(source, "status", document.getStatus());
        source.put("tags", document.getTags() == null ? List.of() : document.getTags());
        source.put("dishNames", document.getDishNames() == null ? List.of() : document.getDishNames());
        return source;
    }

    private void putIfNotNull(Map<String, Object> target, String key, Object value) {
        if (value != null) {
            target.put(key, value);
        }
    }

    private Map<String, Object> buildSearchBody(Region region, ShopSearchQuery query) {
        List<Object> must = new ArrayList<>();
        if (query.getKeyword() != null) {
            must.add(Map.of(
                    "multi_match", Map.of(
                            "query", query.getKeyword(),
                            "fields", List.of("name^5", "namePinyin^2", "categoryName^2", "tags^2", "dishNames", "address"),
                            "type", "best_fields",
                            "fuzziness", "AUTO",
                            "prefix_length", 1
                    )
            ));
        } else {
            must.add(Map.of("match_all", Map.of()));
        }

        List<Object> filters = new ArrayList<>();
        filters.add(termFilter("region", region.name()));
        filters.add(termFilter("status", 1));
        addTermFilter(filters, "categoryId", query.getCategoryId());
        addTermFilter(filters, "cityId", query.getCityId());
        addTermFilter(filters, "areaId", query.getAreaId());
        addTermFilter(filters, "hasDeal", query.getHasDeal());
        addTermFilter(filters, "openNow", query.getOpenNow());
        addRangeFilter(filters, "pricePerCapita", query.getMinPrice(), query.getMaxPrice());
        addRangeFilter(filters, "score", query.getMinScore(), null);

        Map<String, Object> bool = new LinkedHashMap<>();
        bool.put("must", must);
        bool.put("filter", filters);

        Map<String, Object> root = new LinkedHashMap<>();
        root.put("from", query.getOffset());
        root.put("size", query.getPageSize());
        root.put("track_total_hits", true);
        root.put("query", Map.of("bool", bool));
        root.put("sort", buildSort(query));
        return root;
    }

    private List<Object> buildSort(ShopSearchQuery query) {
        return switch (query.getSort()) {
            case "distance" -> List.of(Map.of(
                    "_geo_distance", Map.of(
                            "location", Map.of("lat", query.getLat(), "lon", query.getLng()),
                            "order", "asc",
                            "unit", "m",
                            "distance_type", "arc",
                            "ignore_unmapped", true
                    )
            ));
            case "score" -> List.of(Map.of("score", "desc"), Map.of("reviewCount", "desc"));
            case "popular" -> List.of(Map.of("reviewCount", "desc"), Map.of("score", "desc"));
            default -> List.of(Map.of("_score", "desc"), Map.of("hasDeal", "desc"), Map.of("score", "desc"));
        };
    }

    private Object termFilter(String field, Object value) {
        return Map.of("term", Map.of(field, value));
    }

    private void addTermFilter(List<Object> filters, String field, Object value) {
        if (value != null) {
            filters.add(termFilter(field, value));
        }
    }

    private void addRangeFilter(List<Object> filters, String field, BigDecimal min, BigDecimal max) {
        if (min == null && max == null) {
            return;
        }
        Map<String, Object> range = new LinkedHashMap<>();
        if (min != null) {
            range.put("gte", min);
        }
        if (max != null) {
            range.put("lte", max);
        }
        filters.add(Map.of("range", Map.of(field, range)));
    }

    private PageResult<ShopListItemResponse> mapSearchResponse(String responseBody, ShopSearchQuery query) {
        try {
            JsonNode root = objectMapper.readTree(responseBody == null ? "{}" : responseBody);
            JsonNode hitsNode = root.path("hits");
            long total = hitsNode.path("total").path("value").asLong(0);
            List<ShopListItemResponse> items = new ArrayList<>();
            for (JsonNode hit : hitsNode.path("hits")) {
                JsonNode source = hit.path("_source");
                Double distanceMeters = null;
                if ("distance".equals(query.getSort()) && hit.path("sort").isArray() && !hit.path("sort").isEmpty()) {
                    distanceMeters = hit.path("sort").get(0).asDouble();
                }
                JsonNode location = source.path("location");
                Double latitude = location.path("lat").isNumber() ? location.path("lat").asDouble() : null;
                Double longitude = location.path("lon").isNumber() ? location.path("lon").asDouble() : null;
                items.add(new ShopListItemResponse(
                        source.path("id").asLong(),
                        text(source, "name"),
                        text(source, "coverUrl"),
                        decimal(source, "score"),
                        decimal(source, "pricePerCapita"),
                        text(source, "currency"),
                        text(source, "address"),
                        latitude,
                        longitude,
                        text(source, "areaName"),
                        text(source, "cityName"),
                        source.path("hasDeal").asBoolean(false),
                        source.path("openNow").asBoolean(false),
                        stringList(source.path("tags")),
                        distanceMeters
                ));
            }
            return new PageResult<>(
                    items,
                    total,
                    query.getPage(),
                    query.getPageSize(),
                    query.getOffset() + items.size() < total
            );
        } catch (Exception exception) {
            throw new IllegalStateException("解析 Elasticsearch 搜索响应失败", exception);
        }
    }

    private String text(JsonNode source, String field) {
        JsonNode node = source.path(field);
        return node.isMissingNode() || node.isNull() ? null : node.asText();
    }

    private BigDecimal decimal(JsonNode source, String field) {
        JsonNode node = source.path(field);
        return node.isNumber() ? node.decimalValue() : null;
    }

    private List<String> stringList(JsonNode node) {
        if (!node.isArray()) {
            return List.of();
        }
        List<String> values = new ArrayList<>();
        node.forEach(item -> values.add(item.asText()));
        return values;
    }
}
