package com.tuowei.dazhongdianping.module.points.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.points.mapper.PointsMapper;
import com.tuowei.dazhongdianping.module.points.model.PointsExchangeRow;
import com.tuowei.dazhongdianping.module.points.model.PointsProductRow;
import com.tuowei.dazhongdianping.module.points.model.response.PointsExchangeResponse;
import com.tuowei.dazhongdianping.module.points.model.response.PointsProductResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PointsMallService {

    /** 自动发放：兑换成功即生成兑换码。 */
    private static final int FULFILL_TYPE_AUTO = 1;
    private static final int STATUS_PENDING = 0;
    private static final int STATUS_FULFILLED = 1;
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final PointsMapper pointsMapper;
    private final UserGrowthService userGrowthService;

    public PointsMallService(PointsMapper pointsMapper, UserGrowthService userGrowthService) {
        this.pointsMapper = pointsMapper;
        this.userGrowthService = userGrowthService;
    }

    public PageResult<PointsProductResponse> products(Integer page, Integer pageSize) {
        int currentPage = page == null || page < 1 ? 1 : page;
        int size = pageSize == null ? 12 : Math.max(1, Math.min(pageSize, 50));
        String region = RegionContext.getRegion().name();
        long total = pointsMapper.countOnlineProducts(region);
        List<PointsProductResponse> items = pointsMapper
                .selectOnlineProducts(region, size, (currentPage - 1) * size)
                .stream()
                .map(this::toProductResponse)
                .toList();
        return new PageResult<>(items, total, currentPage, size, (long) currentPage * size < total);
    }

    public PointsProductResponse product(Long productId) {
        PointsProductRow row = pointsMapper.selectOnlineProductById(productId, RegionContext.getRegion().name());
        if (row == null) {
            throw new NotFoundException("商品不存在或已下架");
        }
        return toProductResponse(row);
    }

    @Transactional
    public PointsExchangeResponse exchange(Long productId) {
        UserSession session = requireUserSession();
        String region = RegionContext.getRegion().name();
        PointsProductRow product = pointsMapper.selectProductByIdForUpdate(productId, region);
        if (product == null) {
            throw new NotFoundException("商品不存在或已下架");
        }
        if (valueOrZero(product.getStock()) <= 0) {
            throw new IllegalArgumentException("商品已兑完");
        }
        int limit = valueOrZero(product.getExchangeLimitPerUser());
        if (limit > 0 && pointsMapper.countUserExchanges(session.userId(), productId) >= limit) {
            throw new IllegalArgumentException("已达到该商品的兑换上限");
        }
        if (pointsMapper.decrementProductStock(productId, region) != 1) {
            throw new IllegalArgumentException("商品已兑完");
        }

        int cost = valueOrZero(product.getPointsPrice());
        boolean autoFulfill = valueOrZero(product.getFulfillType()) != 2;
        PointsExchangeRow exchange = new PointsExchangeRow();
        exchange.setUserId(session.userId());
        exchange.setProductId(productId);
        exchange.setProductName(product.getName());
        exchange.setRegion(region);
        exchange.setPointsCost(cost);
        exchange.setQuantity(1);
        exchange.setStatus(autoFulfill ? STATUS_FULFILLED : STATUS_PENDING);
        exchange.setRedeemCode(generateRedeemCode());
        exchange.setRemark(autoFulfill ? "兑换成功，凭兑换码到店使用" : "已受理，等待运营发放");
        exchange.setFulfilledAt(autoFulfill ? LocalDateTime.now() : null);
        pointsMapper.insertExchange(exchange);

        userGrowthService.spendPoints(
                session.userId(),
                UserGrowthService.ACTION_POINTS_EXCHANGE,
                exchange.getId(),
                cost,
                "兑换" + product.getName()
        );
        return toExchangeResponse(exchange);
    }

    public PageResult<PointsExchangeResponse> myExchanges(Integer page, Integer pageSize) {
        UserSession session = requireUserSession();
        int currentPage = page == null || page < 1 ? 1 : page;
        int size = pageSize == null ? 12 : Math.max(1, Math.min(pageSize, 50));
        long total = pointsMapper.countUserExchangesAll(session.userId());
        List<PointsExchangeResponse> items = pointsMapper
                .selectUserExchanges(session.userId(), size, (currentPage - 1) * size)
                .stream()
                .map(this::toExchangeResponse)
                .toList();
        return new PageResult<>(items, total, currentPage, size, (long) currentPage * size < total);
    }

    private PointsProductResponse toProductResponse(PointsProductRow row) {
        int fulfillType = valueOrZero(row.getFulfillType()) == 2 ? 2 : FULFILL_TYPE_AUTO;
        return new PointsProductResponse(
                row.getId(),
                row.getRegion(),
                row.getName(),
                row.getCoverImage() == null ? "" : row.getCoverImage(),
                row.getDescription() == null ? "" : row.getDescription(),
                valueOrZero(row.getPointsPrice()),
                valueOrZero(row.getStock()),
                valueOrZero(row.getExchangeLimitPerUser()),
                valueOrZero(row.getExchangeCount()),
                fulfillType,
                fulfillTypeText(fulfillType),
                valueOrZero(row.getStatus()),
                valueOrZero(row.getSort()),
                valueOrZero(row.getStock()) <= 0,
                format(row.getCreatedAt()),
                format(row.getUpdatedAt())
        );
    }

    private PointsExchangeResponse toExchangeResponse(PointsExchangeRow row) {
        int status = valueOrZero(row.getStatus());
        return new PointsExchangeResponse(
                row.getId(),
                row.getProductId(),
                row.getProductName(),
                valueOrZero(row.getPointsCost()),
                valueOrZero(row.getQuantity()),
                status,
                exchangeStatusText(status),
                // 兑换码占位在下单时就已生成（redeem_code 非空且唯一），但只有「已发放」才对用户可见：
                // 待发放单运营还没实际备货，已取消单更不能让用户误用。
                status == STATUS_FULFILLED ? (row.getRedeemCode() == null ? "" : row.getRedeemCode()) : "",
                row.getRemark() == null ? "" : row.getRemark(),
                format(row.getFulfilledAt()),
                format(row.getCreatedAt())
        );
    }

    public static String fulfillTypeText(int fulfillType) {
        return fulfillType == 2 ? "人工发放" : "自动发放";
    }

    public static String exchangeStatusText(int status) {
        return switch (status) {
            case 1 -> "已发放";
            case 2 -> "已取消";
            default -> "待发放";
        };
    }

    private String generateRedeemCode() {
        return "PT" + UUID.randomUUID().toString().replace("-", "").substring(0, 20).toUpperCase(Locale.ROOT);
    }

    private UserSession requireUserSession() {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return session;
    }

    private int valueOrZero(Integer value) {
        return value == null ? 0 : value;
    }

    private String format(java.time.LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }
}
