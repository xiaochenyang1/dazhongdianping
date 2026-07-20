package com.tuowei.dazhongdianping.module.favorite.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.favorite.mapper.FavoriteMapper;
import com.tuowei.dazhongdianping.module.favorite.model.FavoriteQuery;
import com.tuowei.dazhongdianping.module.favorite.model.FavoriteRow;
import com.tuowei.dazhongdianping.module.favorite.model.request.FavoriteSaveRequest;
import com.tuowei.dazhongdianping.module.favorite.model.response.FavoriteResponse;
import com.tuowei.dazhongdianping.module.favorite.model.response.FavoriteTargetResponse;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class FavoriteService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final FavoriteMapper favoriteMapper;
    public FavoriteService(FavoriteMapper favoriteMapper) { this.favoriteMapper = favoriteMapper; }

    @Transactional
    public FavoriteResponse add(FavoriteSaveRequest request) {
        UserSession session = currentUser();
        requireTarget(request.targetType(), request.targetId());
        FavoriteRow existing = favoriteMapper.selectFavorite(session.userId(), request.targetType(), request.targetId(), RegionContext.getRegion().name());
        if (existing != null) return toResponse(existing);
        FavoriteRow row = new FavoriteRow();
        row.setUserId(session.userId()); row.setTargetType(request.targetType()); row.setTargetId(request.targetId());
        try { favoriteMapper.insertFavorite(row); } catch (DuplicateKeyException ignored) { }
        return toResponse(favoriteMapper.selectFavorite(session.userId(), request.targetType(), request.targetId(), RegionContext.getRegion().name()));
    }

    @Transactional
    public void remove(Integer targetType, Long targetId) {
        validateType(targetType);
        favoriteMapper.deleteFavorite(currentUser().userId(), targetType, targetId);
    }

    public PageResult<FavoriteResponse> list(FavoriteQuery query) {
        query.normalize(); validateType(query.getTargetType());
        query.setUserId(currentUser().userId()); query.setRegion(RegionContext.getRegion().name());
        long total = favoriteMapper.countFavorites(query);
        List<FavoriteResponse> list = favoriteMapper.selectFavorites(query).stream().map(this::toResponse).toList();
        return new PageResult<>(list, total, query.getPage(), query.getPageSize(), query.getOffset() + list.size() < total);
    }

    private void requireTarget(Integer type, Long id) {
        validateType(type);
        boolean missing = type == 2
                ? favoriteMapper.selectPostTarget(id, RegionContext.getRegion().name()) == null
                : favoriteMapper.selectShopTarget(id, RegionContext.getRegion().name()) == null;
        if (missing) throw new NotFoundException(type == 2 ? "帖子不存在" : "门店不存在");
    }
    private void validateType(Integer type) { if (type != null && type != 1 && type != 2) throw new IllegalArgumentException("targetType 只支持 1店铺 2帖子"); }
    private UserSession currentUser() { UserSession session = UserSessionContext.get(); if (session == null) throw new UnauthorizedException("用户登录状态不存在"); return session; }
    private FavoriteResponse toResponse(FavoriteRow row) {
        FavoriteTargetResponse target = new FavoriteTargetResponse(row.getTargetId(), row.getTargetName(), row.getCoverUrl(), row.getScore(), row.getPricePerCapita(), row.getCurrency(), row.getAddress(), row.getCityName(), row.getAreaName(), row.getHasDeal(), row.getOpenNow(), split(row.getTags()));
        return new FavoriteResponse(row.getId(), row.getTargetType(), row.getTargetType() == 1 ? "店铺" : "帖子", row.getTargetId(), target, row.getCreatedAt() == null ? "" : row.getCreatedAt().format(FORMATTER));
    }
    private List<String> split(String tags) { return StringUtils.hasText(tags) ? Arrays.stream(tags.split(",")).map(String::trim).filter(StringUtils::hasText).toList() : List.of(); }
}
