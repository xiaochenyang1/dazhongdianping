package com.tuowei.dazhongdianping.module.dishreview.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.dishreview.mapper.DishReviewMapper;
import com.tuowei.dazhongdianping.module.dishreview.model.DishReviewRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DishReviewService {

    private final DishReviewMapper mapper;

    public DishReviewService(DishReviewMapper mapper) {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> list(Long shopId, Long dishId) {
        String region = region();
        requireDish(shopId, dishId, region);
        return mapper.selectByDish(shopId, dishId, region).stream().map(this::toMap).toList();
    }

    @Transactional
    public Map<String, Object> create(Long shopId, Long dishId, Integer score, String content) {
        UserSession user = requireUser();
        String region = region();
        requireDish(shopId, dishId, region);
        DishReviewRow row = new DishReviewRow();
        row.setRegion(region);
        row.setShopId(shopId);
        row.setDishId(dishId);
        row.setUserId(user.userId());
        row.setScore(score);
        row.setContent(content == null ? "" : content.trim());
        mapper.insert(row);
        return toMap(row);
    }

    private void requireDish(Long shopId, Long dishId, String region) {
        if (!mapper.existsDish(shopId, dishId, region)) {
            throw new NotFoundException("菜品不存在");
        }
    }

    private Map<String, Object> toMap(DishReviewRow row) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("shopId", row.getShopId());
        map.put("dishId", row.getDishId());
        map.put("userId", row.getUserId());
        map.put("score", row.getScore());
        map.put("content", row.getContent());
        map.put("createdAt", row.getCreatedAt());
        return map;
    }

    private UserSession requireUser() {
        UserSession user = UserSessionContext.get();
        if (user == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return user;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
