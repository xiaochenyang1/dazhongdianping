package com.tuowei.dazhongdianping.module.notification.service;

import com.tuowei.dazhongdianping.module.notification.mapper.MentionMapper;
import com.tuowei.dazhongdianping.module.notification.model.MentionUserRow;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class MentionNotificationService {
    private static final String MENTION_NOTIFICATION_TYPE = "social.mention";
    private static final Pattern MENTION_PATTERN = Pattern.compile(
            "(?<![@A-Za-z0-9._%+-])@([\\p{L}\\p{N}_\\-]{1,64})(?![\\p{L}\\p{N}_\\-])"
    );

    private final MentionMapper mentionMapper;
    private final NotificationService notificationService;

    public MentionNotificationService(MentionMapper mentionMapper, NotificationService notificationService) {
        this.mentionMapper = mentionMapper;
        this.notificationService = notificationService;
    }

    public void notifyMentionedUsers(Long actorUserId,
                                     String region,
                                     String text,
                                     String title,
                                     String content,
                                     String linkUrl) {
        if (actorUserId == null || !StringUtils.hasText(region) || !StringUtils.hasText(text)) {
            return;
        }

        List<String> nicknames = extractNicknames(text);
        if (nicknames.isEmpty()) {
            return;
        }

        Map<String, List<MentionUserRow>> usersByNickname = new LinkedHashMap<>();
        for (MentionUserRow row : mentionMapper.selectActiveUsersByNicknames(nicknames)) {
            if (row == null || row.getId() == null || !StringUtils.hasText(row.getNickname())) {
                continue;
            }
            usersByNickname.computeIfAbsent(row.getNickname(), ignored -> new ArrayList<>()).add(row);
        }

        LinkedHashSet<Long> notifiedUserIds = new LinkedHashSet<>();
        for (String nickname : nicknames) {
            List<MentionUserRow> matches = usersByNickname.getOrDefault(nickname, List.of());
            if (matches.size() != 1) {
                continue;
            }
            Long targetUserId = matches.get(0).getId();
            if (targetUserId.equals(actorUserId) || !notifiedUserIds.add(targetUserId)) {
                continue;
            }
            notificationService.create(targetUserId, actorUserId, region, MENTION_NOTIFICATION_TYPE, title, content, linkUrl);
        }
    }

    private List<String> extractNicknames(String text) {
        LinkedHashSet<String> nicknames = new LinkedHashSet<>();
        Matcher matcher = MENTION_PATTERN.matcher(text);
        while (matcher.find()) {
            String nickname = matcher.group(1);
            if (StringUtils.hasText(nickname)) {
                nicknames.add(nickname.trim());
            }
        }
        return new ArrayList<>(nicknames);
    }
}
