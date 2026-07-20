package com.tuowei.dazhongdianping.module.topic.scheduler;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

import com.tuowei.dazhongdianping.module.topic.service.TopicHotRankingService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TopicHotRankingSchedulerTest {

    @Mock private TopicHotRankingService hotRankingService;

    @Test
    void shouldContinueWithEuWhenCnRecalculationFails() {
        doThrow(new IllegalStateException("CN snapshot failed"))
                .when(hotRankingService).recalculateDirtyRegion("CN");

        new TopicHotRankingScheduler(hotRankingService).recalculateHourly();

        verify(hotRankingService).recalculateDirtyRegion("CN");
        verify(hotRankingService).recalculateDirtyRegion("EU");
    }
}
