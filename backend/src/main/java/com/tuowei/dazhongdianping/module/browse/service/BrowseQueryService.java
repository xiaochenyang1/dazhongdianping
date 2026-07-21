package com.tuowei.dazhongdianping.module.browse.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.browse.mapper.BrowseQueryMapper;
import com.tuowei.dazhongdianping.module.browse.model.AreaRow;
import com.tuowei.dazhongdianping.module.browse.model.BannerRow;
import com.tuowei.dazhongdianping.module.browse.model.CategoryRow;
import com.tuowei.dazhongdianping.module.browse.model.CityRow;
import com.tuowei.dazhongdianping.module.browse.model.DishRow;
import com.tuowei.dazhongdianping.module.browse.model.HomeFeedRow;
import com.tuowei.dazhongdianping.module.browse.model.PhotoRow;
import com.tuowei.dazhongdianping.module.browse.model.ReviewRow;
import com.tuowei.dazhongdianping.module.browse.model.SearchHistoryRow;
import com.tuowei.dazhongdianping.module.browse.model.SearchSuggestionRow;
import com.tuowei.dazhongdianping.module.browse.model.ShopDetailRow;
import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.ShopListRow;
import com.tuowei.dazhongdianping.module.browse.model.response.AreaResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.BannerResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.CategoryNodeResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.CityResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.DishResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.HomeFeedItemResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.PhotoResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ReviewPreviewResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.SearchHotWordResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.SearchHistoryResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.SearchSuggestionResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopDetailResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.review.model.response.MerchantReplyResponse;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BrowseQueryService {

    private static final DateTimeFormatter REVIEW_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private final BrowseQueryMapper browseQueryMapper;

    public BrowseQueryService(BrowseQueryMapper browseQueryMapper) {
        this.browseQueryMapper = browseQueryMapper;
    }

    public List<CategoryNodeResponse> listCategories(Region region) {
        List<CategoryRow> rows = browseQueryMapper.selectCategoriesByRegion(region.name());
        Map<Long, List<CategoryRow>> groupedByParent = new LinkedHashMap<>();
        for (CategoryRow row : rows) {
            groupedByParent.computeIfAbsent(row.getParentId(), key -> new ArrayList<>()).add(row);
        }
        return buildCategoryNodes(groupedByParent, 0L);
    }

    public List<CityResponse> listCities(Region region) {
        return browseQueryMapper.selectCitiesByRegion(region.name()).stream()
                .sorted(Comparator.comparing(CityRow::getSortNo))
                .map(row -> new CityResponse(row.getId(), row.getCode(), row.getName()))
                .toList();
    }

    public List<AreaResponse> listAreas(Region region, Long cityId) {
        return browseQueryMapper.selectAreasByRegionAndCity(region.name(), cityId).stream()
                .sorted(Comparator.comparing(AreaRow::getSortNo))
                .map(row -> new AreaResponse(row.getId(), row.getName()))
                .toList();
    }

    public List<BannerResponse> listHomeBanners(Region region, Long cityId) {
        return browseQueryMapper.selectHomeBanners(region.name(), cityId).stream()
                .map(this::toBannerResponse)
                .toList();
    }

    public List<HomeFeedItemResponse> listHomeFeed(Region region, Long cityId, int limit) {
        return browseQueryMapper.selectHomeFeed(region.name(), cityId, limit).stream()
                .map(this::toHomeFeedResponse)
                .toList();
    }

    @Transactional
    public PageResult<ShopListItemResponse> listShops(Region region, ShopListQuery query) {
        query.setRegion(region.name());
        query.normalize();
        recordSearchHistoryIfNeeded(region, query.getKeyword());
        long total = browseQueryMapper.countShops(query);
        List<ShopListItemResponse> items = browseQueryMapper.selectShops(query).stream()
                .map(this::toShopListItemResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    @Transactional
    public ShopDetailResponse getShopDetail(Region region, Long shopId) {
        ShopDetailRow row = browseQueryMapper.selectShopDetail(region.name(), shopId);
        if (row == null) {
            throw new NotFoundException("商户不存在");
        }
        browseQueryMapper.incrementShopView(shopId, java.time.LocalDate.now());
        List<PhotoResponse> photos = browseQueryMapper.selectShopPhotos(shopId).stream()
                .map(this::toPhotoResponse)
                .toList();
        List<DishResponse> dishes = browseQueryMapper.selectShopDishes(shopId).stream()
                .map(this::toDishResponse)
                .toList();
        return new ShopDetailResponse(
                row.getId(),
                row.getName(),
                row.getCoverUrl(),
                row.getScore(),
                row.getTasteScore(),
                row.getEnvScore(),
                row.getServiceScore(),
                row.getPricePerCapita(),
                row.getCurrency(),
                row.getAddress(),
                row.getPhone(),
                row.getBusinessHours(),
                row.getSummary(),
                row.getCategoryName(),
                row.getCityName(),
                row.getAreaName(),
                row.getHasDeal(),
                row.getOpenNow(),
                splitTags(row.getTags()),
                photos,
                dishes
        );
    }

    public List<ShopListItemResponse> listSimilarShops(Region region, Long shopId, int limit) {
        ShopDetailRow source = browseQueryMapper.selectShopDetail(region.name(), shopId);
        if (source == null) {
            throw new NotFoundException("商户不存在");
        }
        return browseQueryMapper.selectSimilarShops(
                        region.name(),
                        shopId,
                        source.getCategoryId(),
                        source.getCityId(),
                        source.getAreaId()
                ).stream()
                .sorted(similarShopComparator(source))
                .limit(limit)
                .map(row -> toShopListItemResponse(row, distanceMeters(source, row)))
                .toList();
    }

    public PageResult<ReviewPreviewResponse> listShopReviews(Region region,
                                                             Long shopId,
                                                             int page,
                                                             int pageSize,
                                                             String sort,
                                                             BigDecimal minScore,
                                                             Boolean hasImages) {
        ensureShopExists(region, shopId);
        if (!List.of("latest", "popular", "score").contains(sort)) {
            throw new IllegalArgumentException("sort 仅支持 latest、popular 或 score");
        }
        int offset = (page - 1) * pageSize;
        long total = browseQueryMapper.countShopReviews(region.name(), shopId, minScore, hasImages);
        List<ReviewPreviewResponse> items = browseQueryMapper.selectShopReviews(
                        region.name(),
                        shopId,
                        sort,
                        minScore,
                        hasImages,
                        pageSize,
                        offset
                ).stream()
                .map(this::toReviewResponse)
                .toList();
        return new PageResult<>(items, total, page, pageSize, offset + items.size() < total);
    }

    public List<SearchSuggestionResponse> listSearchSuggestions(Region region, String keyword, int limit) {
        if (keyword == null || keyword.isBlank()) {
            return List.of();
        }
        int normalizedLimit = normalizeSearchLimit(limit);
        String normalizedKeyword = keyword.trim();
        List<SearchSuggestionResponse> suggestions = new ArrayList<>();
        suggestions.addAll(browseQueryMapper.selectShopSuggestions(region.name(), normalizedKeyword, normalizedLimit).stream()
                .map(this::toSearchSuggestionResponse)
                .toList());
        if (suggestions.size() < normalizedLimit) {
            suggestions.addAll(browseQueryMapper.selectCategorySuggestions(
                            region.name(),
                            normalizedKeyword,
                            normalizedLimit - suggestions.size()
                    ).stream()
                    .map(this::toSearchSuggestionResponse)
                    .filter(item -> suggestions.stream().noneMatch(existing -> Objects.equals(existing.term(), item.term())))
                    .toList());
        }
        return suggestions.size() <= normalizedLimit ? suggestions : suggestions.subList(0, normalizedLimit);
    }

    public List<SearchHotWordResponse> listHotSearchWords(Region region, int limit) {
        Map<String, Integer> counter = new HashMap<>();
        browseQueryMapper.selectCategoryNamesByRegion(region.name()).forEach(term -> addHotTerm(counter, term));
        browseQueryMapper.selectActiveShopTagsByRegion(region.name()).forEach(tags -> addHotTags(counter, tags));
        browseQueryMapper.selectApprovedReviewTagsByRegion(region.name()).forEach(tags -> addHotTags(counter, tags));
        return counter.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed()
                        .thenComparing(Map.Entry::getKey))
                .limit(normalizeSearchLimit(limit))
                .map(entry -> new SearchHotWordResponse(entry.getKey(), entry.getValue()))
                .toList();
    }

    public PageResult<SearchHistoryResponse> listSearchHistory(Region region, int page, int pageSize) {
        UserSession userSession = requireUserSession();
        int normalizedPage = page < 1 ? 1 : page;
        int normalizedPageSize = Math.min(Math.max(pageSize, 1), 50);
        int offset = (normalizedPage - 1) * normalizedPageSize;
        long total = browseQueryMapper.countSearchHistory(userSession.userId(), region.name());
        List<SearchHistoryResponse> items = browseQueryMapper.selectSearchHistory(
                        userSession.userId(),
                        region.name(),
                        normalizedPageSize,
                        offset
                ).stream()
                .map(this::toSearchHistoryResponse)
                .toList();
        return new PageResult<>(items, total, normalizedPage, normalizedPageSize, offset + items.size() < total);
    }

    @Transactional
    public void clearSearchHistory(Region region) {
        UserSession userSession = requireUserSession();
        browseQueryMapper.deleteSearchHistory(userSession.userId(), region.name());
    }

    private void ensureShopExists(Region region, Long shopId) {
        if (browseQueryMapper.selectShopDetail(region.name(), shopId) == null) {
            throw new NotFoundException("商户不存在");
        }
    }

    private List<CategoryNodeResponse> buildCategoryNodes(Map<Long, List<CategoryRow>> groupedByParent, Long parentId) {
        List<CategoryRow> rows = groupedByParent.getOrDefault(parentId, Collections.emptyList());
        rows.sort(Comparator.comparing(CategoryRow::getSortNo));
        return rows.stream()
                .map(row -> new CategoryNodeResponse(row.getId(), row.getName(), buildCategoryNodes(groupedByParent, row.getId())))
                .toList();
    }

    private BannerResponse toBannerResponse(BannerRow row) {
        return new BannerResponse(row.getId(), row.getTitle(), row.getSubtitle(), row.getImageUrl(), row.getLinkUrl());
    }

    private HomeFeedItemResponse toHomeFeedResponse(HomeFeedRow row) {
        return new HomeFeedItemResponse(row.getId(), row.getType(), row.getTitle(), row.getSubtitle(), row.getCoverUrl(), row.getShopId());
    }

    private ShopListItemResponse toShopListItemResponse(ShopListRow row) {
        return toShopListItemResponse(row, null);
    }

    private ShopListItemResponse toShopListItemResponse(ShopListRow row, Double distanceMeters) {
        return new ShopListItemResponse(
                row.getId(),
                row.getName(),
                row.getCoverUrl(),
                row.getScore(),
                row.getPricePerCapita(),
                row.getCurrency(),
                row.getAddress(),
                row.getAreaName(),
                row.getCityName(),
                row.getHasDeal(),
                row.getOpenNow(),
                splitTags(row.getTags()),
                distanceMeters
        );
    }

    private Comparator<ShopListRow> similarShopComparator(ShopDetailRow source) {
        return Comparator.<ShopListRow>comparingInt(row -> similarityScore(source, row)).reversed()
                .thenComparing(row -> distanceMeters(source, row), Comparator.nullsLast(Double::compareTo))
                .thenComparing(ShopListRow::getScore, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(ShopListRow::getId);
    }

    private int similarityScore(ShopDetailRow source, ShopListRow candidate) {
        int score = Objects.equals(source.getCategoryId(), candidate.getCategoryId()) ? 4 : 0;
        score += Objects.equals(source.getAreaId(), candidate.getAreaId()) ? 2 : 0;
        if (splitTags(source.getTags()).stream().anyMatch(splitTags(candidate.getTags())::contains)) {
            score += 1;
        }
        return score;
    }

    private Double distanceMeters(ShopDetailRow source, ShopListRow candidate) {
        if (source.getLatitude() == null || source.getLongitude() == null
                || candidate.getLatitude() == null || candidate.getLongitude() == null) {
            return null;
        }
        double sourceLatitude = Math.toRadians(source.getLatitude());
        double candidateLatitude = Math.toRadians(candidate.getLatitude());
        double latitudeDelta = candidateLatitude - sourceLatitude;
        double longitudeDelta = Math.toRadians(candidate.getLongitude() - source.getLongitude());
        double haversine = Math.pow(Math.sin(latitudeDelta / 2), 2)
                + Math.cos(sourceLatitude) * Math.cos(candidateLatitude)
                * Math.pow(Math.sin(longitudeDelta / 2), 2);
        double distance = 2 * 6_371_000 * Math.asin(Math.sqrt(haversine));
        return Math.round(distance * 10.0) / 10.0;
    }

    private PhotoResponse toPhotoResponse(PhotoRow row) {
        return new PhotoResponse(row.getId(), row.getImageUrl());
    }

    private DishResponse toDishResponse(DishRow row) {
        return new DishResponse(row.getId(), row.getName(), row.getPrice(), row.getRecommendReason());
    }

    private ReviewPreviewResponse toReviewResponse(ReviewRow row) {
        return new ReviewPreviewResponse(
                row.getId(),
                row.getUserName(),
                row.getScore(),
                row.getContent(),
                row.getLikedCount(),
                row.getCommentCount(),
                toMerchantReplyResponse(row),
                row.getCreatedAt().format(REVIEW_TIME_FORMATTER)
        );
    }

    private MerchantReplyResponse toMerchantReplyResponse(ReviewRow row) {
        if (row.getMerchantReplyContent() == null || row.getMerchantReplyContent().isBlank()) {
            return null;
        }
        return new MerchantReplyResponse(
                row.getMerchantReplyMerchantName(),
                row.getMerchantReplyContent(),
                row.getMerchantReplyCreatedAt() == null ? "" : row.getMerchantReplyCreatedAt().format(REVIEW_TIME_FORMATTER),
                row.getMerchantReplyUpdatedAt() == null ? "" : row.getMerchantReplyUpdatedAt().format(REVIEW_TIME_FORMATTER)
        );
    }

    private SearchSuggestionResponse toSearchSuggestionResponse(SearchSuggestionRow row) {
        return new SearchSuggestionResponse(row.getTerm(), row.getType(), row.getRefId());
    }

    private SearchHistoryResponse toSearchHistoryResponse(SearchHistoryRow row) {
        return new SearchHistoryResponse(
                row.getId(),
                row.getKeyword(),
                row.getRegion(),
                row.getSearchType(),
                row.getUpdatedAt().format(REVIEW_TIME_FORMATTER)
        );
    }

    private void recordSearchHistoryIfNeeded(Region region, String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return;
        }
        UserSession userSession = UserSessionContext.get();
        if (userSession == null) {
            return;
        }
        String normalizedKeyword = keyword.trim();
        SearchHistoryRow existing = browseQueryMapper.selectSearchHistoryByUserRegionKeyword(
                userSession.userId(),
                region.name(),
                normalizedKeyword
        );
        if (existing != null) {
            browseQueryMapper.touchSearchHistory(existing.getId());
            return;
        }
        SearchHistoryRow row = new SearchHistoryRow();
        row.setUserId(userSession.userId());
        row.setRegion(region.name());
        row.setKeyword(normalizedKeyword);
        row.setSearchType(1);
        browseQueryMapper.insertSearchHistory(row);
    }

    private UserSession requireUserSession() {
        UserSession userSession = UserSessionContext.get();
        if (userSession == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return userSession;
    }

    private void addHotTags(Map<String, Integer> counter, String tags) {
        splitTags(tags).forEach(term -> addHotTerm(counter, term));
    }

    private void addHotTerm(Map<String, Integer> counter, String term) {
        if (term == null || term.isBlank()) {
            return;
        }
        counter.merge(term.trim(), 1, Integer::sum);
    }

    private int normalizeSearchLimit(int limit) {
        if (limit < 1) {
            return 8;
        }
        return Math.min(limit, 20);
    }

    private List<String> splitTags(String tags) {
        if (tags == null || tags.isBlank()) {
            return List.of();
        }
        return List.of(tags.split(",")).stream()
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .map(value -> value.toLowerCase(Locale.ROOT).equals(value) ? value : value)
                .toList();
    }
}
