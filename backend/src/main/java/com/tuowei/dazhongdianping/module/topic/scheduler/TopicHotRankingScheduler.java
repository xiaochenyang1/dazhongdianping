package com.tuowei.dazhongdianping.module.topic.scheduler;

import com.tuowei.dazhongdianping.module.topic.service.TopicHotRankingService;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class TopicHotRankingScheduler {
    private final TopicHotRankingService hotRankingService;

    public TopicHotRankingScheduler(TopicHotRankingService hotRankingService) {
        this.hotRankingService = hotRankingService;
    }

    @Scheduled(cron = "0 0 * * * *")
    public void recalculateHourly() {
        for (String region : List.of("CN", "EU")) {
            try {
                hotRankingService.recalculateDirtyRegion(region);
            } catch (RuntimeException exception) {
                log.error("topic hot ranking recalculation failed, region={}", region, exception);
            }
        }
    }
}
