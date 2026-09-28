package com.tuowei.dazhongdianping.module.riskcontrol.service;

import com.tuowei.dazhongdianping.module.riskcontrol.mapper.RiskMapper;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventRow;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 风控命中事件的持久化器。用独立事务（REQUIRES_NEW）落库，使审计记录不随主业务事务回滚而丢失——
 * 典型场景：点评提交命中 BLOCK 规则时，{@code ReviewService.createReview} 的事务会回滚，
 * 若事件写在同一事务内则被拦截的审计痕迹一并消失，只有放行/转审的记录能留痕。
 *
 * <p>注意：此处只写全新插入的 risk_event（不与主事务争行锁）。设备命中计数
 * ({@code incrementDeviceRiskHit}) 会更新主事务刚写过的 device_fingerprint 行，
 * 若放进本独立事务会与被挂起的主事务互相等待造成死锁，故仍留在主事务内执行。
 */
@Component
public class RiskEventRecorder {

    private final RiskMapper riskMapper;

    public RiskEventRecorder(RiskMapper riskMapper) {
        this.riskMapper = riskMapper;
    }

    /** 在新事务中落风控事件，独立于调用方事务提交（调用方回滚也不影响审计留痕）。 */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(RiskEventRow row) {
        riskMapper.insertEvent(row);
    }
}

