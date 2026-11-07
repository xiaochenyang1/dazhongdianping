package com.tuowei.dazhongdianping.module.admin.groupbuy.mapper;

import com.tuowei.dazhongdianping.module.admin.groupbuy.model.AdminGroupBuySummaryRow;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.AdminGroupBuyTeamRow;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminGroupBuyOperationsMapper {

    AdminGroupBuySummaryRow selectSummary(
            @Param("region") String region,
            @Param("since") LocalDateTime since,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    long countTeams(
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("problemOnly") boolean problemOnly,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    List<AdminGroupBuyTeamRow> selectTeams(
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("problemOnly") boolean problemOnly,
            @Param("limit") int limit,
            @Param("offset") int offset,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);

    AdminGroupBuyTeamRow selectTeam(
            @Param("region") String region,
            @Param("teamId") Long teamId,
            @Param("allCities") boolean allCities,
            @Param("cityIds") Set<Long> cityIds,
            @Param("shopIds") Set<Long> shopIds);
}
