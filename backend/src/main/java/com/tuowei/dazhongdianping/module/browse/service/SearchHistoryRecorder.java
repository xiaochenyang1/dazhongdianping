package com.tuowei.dazhongdianping.module.browse.service;

import com.tuowei.dazhongdianping.module.browse.mapper.BrowseQueryMapper;
import com.tuowei.dazhongdianping.module.browse.model.SearchHistoryRow;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Persists a logged-in user's search history off the request thread so search
 * responses are not delayed by the history bookkeeping round-trips. The write
 * runs on {@code searchHistoryTaskExecutor}; the caller must resolve the user id
 * and region on the request thread first, because the async thread has no access
 * to the {@code UserSessionContext} / {@code RegionContext} thread-locals. A
 * failed history write is logged and swallowed — it must never break the search.
 *
 * <p>Search history therefore becomes eventually consistent in production (the
 * new term appears a fraction of a second after the search). Tests bind a
 * synchronous executor (see {@code SearchHistoryAsyncTestConfig}) so the existing
 * read-after-write assertions and transactional rollback isolation still hold.
 */
@Component
public class SearchHistoryRecorder {

    private static final Logger LOGGER = LoggerFactory.getLogger(SearchHistoryRecorder.class);
    /** 每个登录用户在同一区域最多保留的搜索历史条数。 */
    private static final int SEARCH_HISTORY_LIMIT = 20;

    private final BrowseQueryMapper browseQueryMapper;

    public SearchHistoryRecorder(BrowseQueryMapper browseQueryMapper) {
        this.browseQueryMapper = browseQueryMapper;
    }

    @Async("searchHistoryTaskExecutor")
    @Transactional
    public void record(Long userId, String region, String normalizedKeyword) {
        try {
            SearchHistoryRow existing = browseQueryMapper.selectSearchHistoryByUserRegionKeyword(
                    userId, region, normalizedKeyword);
            if (existing != null) {
                browseQueryMapper.touchSearchHistory(existing.getId());
            } else {
                SearchHistoryRow row = new SearchHistoryRow();
                row.setUserId(userId);
                row.setRegion(region);
                row.setKeyword(normalizedKeyword);
                row.setSearchType(1);
                browseQueryMapper.insertSearchHistory(row);
            }
            browseQueryMapper.deleteExcessSearchHistory(userId, region, SEARCH_HISTORY_LIMIT);
        } catch (RuntimeException ex) {
            LOGGER.warn("记录搜索历史失败 userId={} region={}: {}", userId, region, ex.getMessage());
            LOGGER.debug("搜索历史写入异常", ex);
        }
    }
}
