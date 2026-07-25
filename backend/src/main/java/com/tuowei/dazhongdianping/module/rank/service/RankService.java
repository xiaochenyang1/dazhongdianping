package com.tuowei.dazhongdianping.module.rank.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.merchant.verification.model.response.MerchantVerificationBadgeResponse;
import com.tuowei.dazhongdianping.module.merchant.verification.service.MerchantVerificationService;
import com.tuowei.dazhongdianping.module.rank.mapper.RankMapper;
import com.tuowei.dazhongdianping.module.rank.model.RankItemRow;
import com.tuowei.dazhongdianping.module.rank.model.RankSummaryRow;
import com.tuowei.dazhongdianping.module.rank.model.response.RankDetailResponse;
import com.tuowei.dazhongdianping.module.rank.model.response.RankItemResponse;
import com.tuowei.dazhongdianping.module.rank.model.response.RankShopResponse;
import com.tuowei.dazhongdianping.module.rank.model.response.RankSummaryResponse;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class RankService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final RankMapper rankMapper;
    private final MerchantVerificationService merchantVerificationService;

    public RankService(RankMapper rankMapper, MerchantVerificationService merchantVerificationService) {
        this.rankMapper = rankMapper;
        this.merchantVerificationService = merchantVerificationService;
    }

    public List<RankSummaryResponse> list(Region region, Long cityId, Long categoryId, Integer type) {
        validateType(type);
        return rankMapper.selectRanks(region.name(), cityId, categoryId, type).stream().map(this::toSummary).toList();
    }

    public RankDetailResponse detail(Region region, Long rankId) {
        RankSummaryRow rank = rankMapper.selectRank(rankId, region.name());
        if (rank == null) {
            throw new NotFoundException("榜单不存在");
        }
        List<RankItemRow> rows = rankMapper.selectRankItems(rankId, region.name());
        Map<Long, MerchantVerificationBadgeResponse> badges = merchantVerificationService.approvedBadges(
                rows.stream().map(RankItemRow::getMerchantId).toList(),
                region.name()
        );
        List<RankItemResponse> items = rows.stream()
                .map(row -> toItem(row, badges.get(row.getMerchantId())))
                .toList();
        return new RankDetailResponse(
                rank.getId(), rank.getName(), rank.getType(), typeText(rank.getType()), rank.getRegion(),
                rank.getCityId(), rank.getCityName(), rank.getCategoryId(), rank.getCategoryName(),
                rank.getPeriod(), format(rank), items
        );
    }

    private RankSummaryResponse toSummary(RankSummaryRow row) {
        return new RankSummaryResponse(
                row.getId(), row.getName(), row.getType(), typeText(row.getType()), row.getRegion(),
                row.getCityId(), row.getCityName(), row.getCategoryId(), row.getCategoryName(), row.getPeriod(),
                row.getItemCount(), row.getCoverUrl(), row.getTopShopName(), format(row)
        );
    }

    private RankItemResponse toItem(RankItemRow row, MerchantVerificationBadgeResponse badge) {
        RankShopResponse shop = new RankShopResponse(
                row.getShopId(),
                row.getMerchantId(),
                row.getShopName(),
                row.getCoverUrl(),
                row.getScore(),
                row.getPricePerCapita(),
                row.getCurrency(),
                row.getAddress(),
                row.getCityName(),
                row.getAreaName(),
                row.getHasDeal(),
                row.getOpenNow(),
                splitTags(row.getTags()),
                badge
        );
        return new RankItemResponse(row.getPosition(), row.getRankScore(), row.getReason(), shop);
    }

    private void validateType(Integer type) {
        if (type != null && (type < 1 || type > 3)) {
            throw new IllegalArgumentException("type 只支持 1必吃榜 2好评榜 3热门榜");
        }
    }

    private String typeText(Integer type) {
        return switch (type == null ? 0 : type) {
            case 1 -> "必吃榜";
            case 2 -> "好评榜";
            case 3 -> "热门榜";
            default -> "未知榜单";
        };
    }

    private List<String> splitTags(String tags) {
        if (!StringUtils.hasText(tags)) {
            return List.of();
        }
        return Arrays.stream(tags.split(",")).map(String::trim).filter(StringUtils::hasText).toList();
    }

    private String format(RankSummaryRow row) {
        return row.getUpdatedAt() == null ? "" : row.getUpdatedAt().format(FORMATTER);
    }
}
