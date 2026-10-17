package com.tuowei.dazhongdianping.module.reservation.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.module.reservation.mapper.ReservationMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationShopRow;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReservationAvailabilityService {
    private final ReservationMapper mapper;

    public ReservationAvailabilityService(ReservationMapper mapper) {
        this.mapper = mapper;
    }

    public ReservationShopRow requireAvailable(Long shopId, String region) {
        return require(mapper.selectBookableShop(shopId, region, false));
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public ReservationShopRow lockAvailable(Long shopId, String region) {
        // Lock the shop and its active geography until booking/slot changes commit.
        return require(mapper.selectBookableShop(shopId, region, true));
    }

    private ReservationShopRow require(ReservationShopRow shop) {
        if (shop == null) {
            throw new NotFoundException("门店当前不可预订");
        }
        return shop;
    }
}
