package com.tuowei.dazhongdianping.module.notification.service;

import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.topic.mapper.TopicMapper;
import com.tuowei.dazhongdianping.module.topic.model.TopicRow;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

/**
 * 帖子审核通过后，向关联话题的关注者发送站内更新通知。
 * 同一用户关注多个相关话题时只提醒一次；作者本人不提醒。
 */
@Service
public class TopicUpdateNotificationService {
    public static final String TOPIC_UPDATE_TYPE = "topic.update";

    private final TopicMapper topicMapper;
    private final NotificationService notificationService;

    public TopicUpdateNotificationService(TopicMapper topicMapper, NotificationService notificationService) {
        this.topicMapper = topicMapper;
        this.notificationService = notificationService;
    }

    public void notifyTopicFollowers(PostRow post) {
        if (post == null || post.getId() == null || !StringUtils.hasText(post.getRegion())) {
            return;
        }

        List<Long> topicIds = topicMapper.selectPostTopicIds(post.getId());
        if (topicIds == null || topicIds.isEmpty()) {
            return;
        }

        String region = post.getRegion().trim();
        Long authorId = post.getUserId();
        String authorName = StringUtils.hasText(post.getUserName()) ? post.getUserName().trim() : "有人";
        String postTitle = preview(post.getTitle());
        String linkUrl = "/community/posts/" + post.getId();

        Set<Long> notifiedUserIds = new LinkedHashSet<>();
        for (Long topicId : topicIds) {
            if (topicId == null) {
                continue;
            }
            TopicRow topic = topicMapper.selectByIdAnyStatus(topicId, region);
            if (topic == null || !Integer.valueOf(1).equals(topic.getStatus()) || topic.getMergedToId() != null) {
                continue;
            }
            String topicName = StringUtils.hasText(topic.getName()) ? topic.getName().trim() : "话题";
            List<Long> followerIds = topicMapper.selectFollowerUserIds(topicId);
            if (followerIds == null || followerIds.isEmpty()) {
                continue;
            }
            for (Long followerId : followerIds) {
                if (followerId == null) {
                    continue;
                }
                if (authorId != null && authorId.equals(followerId)) {
                    continue;
                }
                if (!notifiedUserIds.add(followerId)) {
                    continue;
                }
                String title = "关注的话题有新内容";
                String content = authorName + " 在 #" + topicName + " 发布了《" + postTitle + "》";
                notificationService.create(
                        followerId,
                        authorId,
                        region,
                        TOPIC_UPDATE_TYPE,
                        title,
                        content,
                        linkUrl
                );
            }
        }
    }

    private String preview(String text) {
        if (!StringUtils.hasText(text)) {
            return "新帖子";
        }
        String normalized = text.trim();
        return normalized.length() <= 24 ? normalized : normalized.substring(0, 24) + "...";
    }
}
