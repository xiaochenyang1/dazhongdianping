package com.tuowei.dazhongdianping.module.rank.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.rank.mapper.RankMapper;
import com.tuowei.dazhongdianping.module.rank.model.RankCandidateRow;
import com.tuowei.dazhongdianping.module.rank.model.RankConfigRow;
import com.tuowei.dazhongdianping.module.rank.model.RankSnapshotItemRow;
import com.tuowei.dazhongdianping.module.rank.model.RankSnapshotRow;
import com.tuowei.dazhongdianping.module.rank.model.request.RankConfigSaveRequest;
import com.tuowei.dazhongdianping.module.rank.model.response.RankConfigResponse;
import com.tuowei.dazhongdianping.module.rank.model.response.RankPublishResponse;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminRankService {
    private static final Set<String> SUPPORTED_WEIGHTS = Set.of("score", "reviewCount", "hasDeal", "openNow", "manualBoost");
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final RankMapper rankMapper;
    private final ObjectMapper objectMapper;

    public AdminRankService(RankMapper rankMapper, ObjectMapper objectMapper) {
        this.rankMapper = rankMapper;
        this.objectMapper = objectMapper;
    }

    public List<RankConfigResponse> list() {
        return rankMapper.selectRankConfigs(currentRegion().name()).stream().map(this::toResponse).toList();
    }

    @Transactional
    public RankConfigResponse createDraft(RankConfigSaveRequest request) {
        Region region = requireRegion(request.getRegion());
        validateWeight(request.getWeight());
        requireScope(region, request.getCityId(), request.getCategoryId());
        RankConfigRow row = new RankConfigRow();
        row.setRankType(request.getRankType());
        row.setRegion(region.name());
        row.setCityId(request.getCityId());
        row.setCategoryId(request.getCategoryId());
        row.setVersion(rankMapper.selectNextConfigVersion(row.getRankType(), row.getRegion(), row.getCityId(), row.getCategoryId()));
        row.setCalcCycle(request.getCalcCycle());
        row.setWeightJson(writeWeight(request.getWeight()));
        row.setMinReviewCount(request.getMinReviewCount());
        row.setMinScore(request.getMinScore());
        row.setManualIntervene(Boolean.TRUE.equals(request.getManualIntervene()));
        row.setStatus(0);
        row.setUpdatedBy(AdminSessionContext.get().adminId());
        rankMapper.insertRankConfig(row);
        return toResponse(rankMapper.selectRankConfig(row.getId(), row.getRegion()));
    }

    @Transactional
    public RankConfigResponse updateDraft(Long configId, RankConfigSaveRequest request) {
        RankConfigRow existing = requireConfig(configId);
        if (existing.getStatus() != 0) throw new IllegalArgumentException("只有草稿规则可以编辑");
        Region region = requireRegion(request.getRegion());
        validateWeight(request.getWeight());
        requireScope(region, request.getCityId(), request.getCategoryId());
        existing.setRankType(request.getRankType());
        existing.setCityId(request.getCityId());
        existing.setCategoryId(request.getCategoryId());
        existing.setCalcCycle(request.getCalcCycle());
        existing.setWeightJson(writeWeight(request.getWeight()));
        existing.setMinReviewCount(request.getMinReviewCount());
        existing.setMinScore(request.getMinScore());
        existing.setManualIntervene(Boolean.TRUE.equals(request.getManualIntervene()));
        if (rankMapper.updateDraftRankConfig(existing) == 0) throw new IllegalArgumentException("草稿规则更新失败");
        return toResponse(rankMapper.selectRankConfig(configId, existing.getRegion()));
    }

    @Transactional
    public RankPublishResponse publish(Long configId) {
        RankConfigRow config = requireConfig(configId);
        Map<String, BigDecimal> weight = readWeight(config.getWeightJson());
        validateWeight(weight);
        List<RankCandidateRow> candidates = rankMapper.selectRankCandidates(config);
        if (candidates.isEmpty()) {
            throw new IllegalArgumentException("当前规则没有可入榜门店，旧榜单保持不变");
        }
        List<ScoredCandidate> scored = candidates.stream()
                .map(candidate -> new ScoredCandidate(candidate, calculate(candidate, weight)))
                .sorted(Comparator.comparing(ScoredCandidate::score).reversed().thenComparing(item -> item.row().getShopId()))
                .limit(50)
                .toList();

        rankMapper.archivePublishedConfigs(config);
        rankMapper.publishRankConfig(config.getId(), config.getRegion());
        rankMapper.disableRankSnapshots(config);

        RankSnapshotRow snapshot = new RankSnapshotRow();
        snapshot.setName(buildName(config));
        snapshot.setType(config.getRankType());
        snapshot.setRegion(config.getRegion());
        snapshot.setCityId(config.getCityId());
        snapshot.setCategoryId(config.getCategoryId());
        snapshot.setConfigId(config.getId());
        snapshot.setPeriod(period(config.getCalcCycle()));
        rankMapper.insertRankSnapshot(snapshot);

        int position = 1;
        for (ScoredCandidate item : scored) {
            RankSnapshotItemRow row = new RankSnapshotItemRow();
            row.setRankId(snapshot.getId());
            row.setShopId(item.row().getShopId());
            row.setPosition(position++);
            row.setScore(item.score());
            row.setReason(reason(item.row()));
            rankMapper.insertRankSnapshotItem(row);
        }
        return new RankPublishResponse(toResponse(rankMapper.selectRankConfig(configId, config.getRegion())), snapshot.getId(), scored.size());
    }

    @Transactional
    public RankPublishResponse rollback(Long configId) {
        RankConfigRow source = requireConfig(configId);
        RankConfigSaveRequest request = new RankConfigSaveRequest();
        request.setRankType(source.getRankType());
        request.setRegion(source.getRegion());
        request.setCityId(source.getCityId());
        request.setCategoryId(source.getCategoryId());
        request.setCalcCycle(source.getCalcCycle());
        request.setWeight(readWeight(source.getWeightJson()));
        request.setMinReviewCount(source.getMinReviewCount());
        request.setMinScore(source.getMinScore());
        request.setManualIntervene(source.getManualIntervene());
        RankConfigResponse draft = createDraft(request);
        return publish(draft.id());
    }

    private RankConfigRow requireConfig(Long configId) {
        RankConfigRow row = rankMapper.selectRankConfig(configId, currentRegion().name());
        if (row == null) throw new NotFoundException("榜单规则不存在");
        return row;
    }

    private void requireScope(Region region, Long cityId, Long categoryId) {
        if (rankMapper.selectCityName(cityId, region.name()) == null) throw new IllegalArgumentException("城市不存在或不属于当前区域");
        if (rankMapper.selectCategoryName(categoryId, region.name()) == null) throw new IllegalArgumentException("分类不存在或不属于当前区域");
    }

    private void validateWeight(Map<String, BigDecimal> weight) {
        if (!SUPPORTED_WEIGHTS.containsAll(weight.keySet())) throw new IllegalArgumentException("榜单权重包含尚未支持的数据源");
        BigDecimal total = weight.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        if (total.compareTo(BigDecimal.ONE) != 0) throw new IllegalArgumentException("榜单权重之和必须等于 1");
        if (weight.values().stream().anyMatch(value -> value.compareTo(BigDecimal.ZERO) < 0)) throw new IllegalArgumentException("榜单权重不能为负数");
    }

    private BigDecimal calculate(RankCandidateRow row, Map<String, BigDecimal> weight) {
        BigDecimal result = row.getScore().multiply(BigDecimal.valueOf(20)).multiply(weight.getOrDefault("score", BigDecimal.ZERO));
        result = result.add(BigDecimal.valueOf(Math.min(row.getReviewCount(), 100)).multiply(weight.getOrDefault("reviewCount", BigDecimal.ZERO)));
        if (Boolean.TRUE.equals(row.getHasDeal())) result = result.add(BigDecimal.valueOf(100).multiply(weight.getOrDefault("hasDeal", BigDecimal.ZERO)));
        if (Boolean.TRUE.equals(row.getOpenNow())) result = result.add(BigDecimal.valueOf(100).multiply(weight.getOrDefault("openNow", BigDecimal.ZERO)));
        return result.setScale(2, RoundingMode.HALF_UP);
    }

    private String buildName(RankConfigRow config) {
        return rankMapper.selectCityName(config.getCityId(), config.getRegion())
                + rankMapper.selectCategoryName(config.getCategoryId(), config.getRegion())
                + rankTypeText(config.getRankType());
    }

    private String reason(RankCandidateRow row) { return "综合评分 " + row.getScore() + "，点评 " + row.getReviewCount() + " 条，按当前发布规则入榜。"; }
    private String period(Integer cycle) { return switch (cycle) { case 1 -> LocalDate.now().toString(); case 2 -> LocalDate.now().getYear() + "-W" + LocalDate.now().get(java.time.temporal.IsoFields.WEEK_OF_WEEK_BASED_YEAR); case 3 -> LocalDate.now().getYear() + "-" + String.format("%02d", LocalDate.now().getMonthValue()); default -> LocalDate.now().getYear() + "-Q" + ((LocalDate.now().getMonthValue() - 1) / 3 + 1); }; }
    private Region requireRegion(String value) { Region region; try { region = Region.valueOf(value.trim().toUpperCase(Locale.ROOT)); } catch (Exception e) { throw new IllegalArgumentException("region 非法"); } if (region != currentRegion()) throw new IllegalArgumentException("region 必须与请求头 X-Region 一致"); return region; }
    private Region currentRegion() { return RegionContext.getRegion(); }
    private String writeWeight(Map<String, BigDecimal> weight) { try { return objectMapper.writeValueAsString(new LinkedHashMap<>(weight)); } catch (Exception e) { throw new IllegalArgumentException("榜单权重序列化失败", e); } }
    private Map<String, BigDecimal> readWeight(String json) { try { return objectMapper.readValue(json, new TypeReference<>() {}); } catch (Exception e) { throw new IllegalStateException("榜单权重解析失败", e); } }
    private RankConfigResponse toResponse(RankConfigRow row) { return new RankConfigResponse(row.getId(), row.getRankType(), rankTypeText(row.getRankType()), row.getRegion(), row.getCityId(), row.getCategoryId(), row.getVersion(), row.getCalcCycle(), readWeight(row.getWeightJson()), row.getMinReviewCount(), row.getMinScore(), row.getManualIntervene(), row.getStatus(), statusText(row.getStatus()), format(row.getEffectiveFrom()), format(row.getUpdatedAt())); }
    private String rankTypeText(Integer type) { return switch (type) { case 1 -> "必吃榜"; case 2 -> "好评榜"; case 3 -> "热门榜"; default -> "未知榜单"; }; }
    private String statusText(Integer status) { return switch (status) { case 1 -> "已发布"; case 2 -> "已归档"; default -> "草稿"; }; }
    private String format(LocalDateTime value) { return value == null ? "" : value.format(FORMATTER); }
    private record ScoredCandidate(RankCandidateRow row, BigDecimal score) {}
}
