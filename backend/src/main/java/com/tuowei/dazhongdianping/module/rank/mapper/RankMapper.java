package com.tuowei.dazhongdianping.module.rank.mapper;

import com.tuowei.dazhongdianping.module.rank.model.RankItemRow;
import com.tuowei.dazhongdianping.module.rank.model.RankCandidateRow;
import com.tuowei.dazhongdianping.module.rank.model.RankConfigRow;
import com.tuowei.dazhongdianping.module.rank.model.RankSnapshotItemRow;
import com.tuowei.dazhongdianping.module.rank.model.RankSnapshotRow;
import com.tuowei.dazhongdianping.module.rank.model.RankSummaryRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface RankMapper {
    List<RankSummaryRow> selectRanks(@Param("region") String region,
                                     @Param("cityId") Long cityId,
                                     @Param("categoryId") Long categoryId,
                                     @Param("type") Integer type);

    RankSummaryRow selectRank(@Param("rankId") Long rankId, @Param("region") String region);

    List<RankItemRow> selectRankItems(@Param("rankId") Long rankId, @Param("region") String region);

    List<RankConfigRow> selectRankConfigs(@Param("region") String region);
    RankConfigRow selectRankConfig(@Param("configId") Long configId, @Param("region") String region);
    int selectNextConfigVersion(@Param("rankType") Integer rankType, @Param("region") String region,
                                @Param("cityId") Long cityId, @Param("categoryId") Long categoryId);
    void insertRankConfig(RankConfigRow row);
    int updateDraftRankConfig(RankConfigRow row);
    void archivePublishedConfigs(RankConfigRow row);
    void publishRankConfig(@Param("configId") Long configId, @Param("region") String region);
    List<RankCandidateRow> selectRankCandidates(RankConfigRow row);
    String selectCityName(@Param("cityId") Long cityId, @Param("region") String region);
    String selectCategoryName(@Param("categoryId") Long categoryId, @Param("region") String region);
    void disableRankSnapshots(RankConfigRow row);
    void insertRankSnapshot(RankSnapshotRow row);
    void insertRankSnapshotItem(RankSnapshotItemRow row);
}
