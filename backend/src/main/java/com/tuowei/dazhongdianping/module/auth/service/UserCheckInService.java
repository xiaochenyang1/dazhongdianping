package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.auth.model.UserCheckInRow;
import com.tuowei.dazhongdianping.module.auth.model.response.UserCheckInStatusResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserCheckInService {

    private static final String ACTION_CHECK_IN = "check_in";
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AuthCommandMapper authCommandMapper;
    private final UserGrowthService userGrowthService;

    public UserCheckInService(AuthCommandMapper authCommandMapper,
                              UserGrowthService userGrowthService) {
        this.authCommandMapper = authCommandMapper;
        this.userGrowthService = userGrowthService;
    }

    @Transactional
    public UserCheckInStatusResponse checkIn() {
        UserSession session = requireUserSession();
        LocalDate today = LocalDate.now();
        if (authCommandMapper.selectUserCheckInOnDate(session.userId(), today) != null) {
            throw new IllegalArgumentException("今天已经签过到了");
        }

        UserCheckInRow last = authCommandMapper.selectLatestUserCheckIn(session.userId());
        int streak = last != null && last.getCheckInDate().equals(today.minusDays(1))
                ? valueOrZero(last.getStreakDays()) + 1
                : 1;

        GrowthRuleRow rule = authCommandMapper.selectEnabledGrowthRule(ACTION_CHECK_IN);
        UserCheckInRow row = new UserCheckInRow();
        row.setUserId(session.userId());
        row.setCheckInDate(today);
        row.setStreakDays(streak);
        row.setGrowthValue(rule == null ? 0 : valueOrZero(rule.getGrowthValue()));
        row.setPoints(rule == null ? 0 : valueOrZero(rule.getPoints()));
        try {
            authCommandMapper.insertUserCheckIn(row);
        } catch (DuplicateKeyException duplicate) {
            throw new IllegalArgumentException("今天已经签过到了");
        }
        userGrowthService.rewardForCheckIn(session.userId(), row.getId());
        return statusOf(session.userId());
    }

    public UserCheckInStatusResponse status() {
        UserSession session = requireUserSession();
        return statusOf(session.userId());
    }

    private UserCheckInStatusResponse statusOf(Long userId) {
        LocalDate today = LocalDate.now();
        UserCheckInRow todayRow = authCommandMapper.selectUserCheckInOnDate(userId, today);
        UserCheckInRow last = authCommandMapper.selectLatestUserCheckIn(userId);
        long total = authCommandMapper.countUserCheckIns(userId);
        GrowthRuleRow rule = authCommandMapper.selectEnabledGrowthRule(ACTION_CHECK_IN);
        int streak = last != null && !last.getCheckInDate().isBefore(today.minusDays(1))
                ? valueOrZero(last.getStreakDays())
                : 0;
        return new UserCheckInStatusResponse(
                todayRow != null,
                streak,
                total,
                todayRow == null
                        ? rule == null ? 0 : valueOrZero(rule.getGrowthValue())
                        : valueOrZero(todayRow.getGrowthValue()),
                todayRow == null
                        ? rule == null ? 0 : valueOrZero(rule.getPoints())
                        : valueOrZero(todayRow.getPoints()),
                last == null ? null : format(last.getCreatedAt())
        );
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

    private String format(LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }
}
