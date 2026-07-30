import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizations provide simplified, traditional and English text', () {
    expect(AppLocalizations.forTag('zh-CN').homeTitle, '本地生活');
    expect(AppLocalizations.forTag('zh-TW').homeTitle, '在地生活');
    expect(AppLocalizations.forTag('en').homeTitle, 'Local life');
    expect(AppLocalizations.forTag('zh_HK').searchTitle, '搜尋結果');
    expect(AppLocalizations.forTag('en').recentSearches, 'Recent searches');
    expect(
      AppLocalizations.forTag('en').searchFailed('offline'),
      'Search failed: offline',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).detailRefreshFailed(StateError('network unavailable')),
      'Could not refresh details: network unavailable',
    );
    expect(
      AppLocalizations.forTag(
        'zh-CN',
      ).actionFailed(Exception('send unavailable')),
      '操作失败：send unavailable',
    );
    expect(AppLocalizations.forTag('zh-CN').cityRankings, '城市榜单');
    expect(AppLocalizations.forTag('zh-TW').cityRankings, '城市排行榜');
    expect(AppLocalizations.forTag('en').cityRankings, 'City rankings');
    expect(AppLocalizations.forTag('en').rankDetailTitle, 'Ranking details');
    expect(AppLocalizations.forTag('en').activities, 'Activities');
    expect(
      AppLocalizations.forTag('en').activityDetailTitle,
      'Activity details',
    );
    expect(AppLocalizations.forTag('zh-CN').requestFailed, '请求失败');
    expect(AppLocalizations.forTag('zh-TW').invalidApiResponse, '服務回傳格式異常');
    expect(
      AppLocalizations.forTag('en').invalidApiResponse,
      'The server returned invalid data',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).unsupportedApiClientCapability('PUT requests'),
      'This API client does not support PUT requests',
    );
    expect(AppLocalizations.forTag('zh-CN').shopCount(10), '10 家门店');
    expect(AppLocalizations.forTag('en').shopCount(10), '10 places');
    expect(
      AppLocalizations.forTag('en').topShop('Hotpot House'),
      'Top place: Hotpot House',
    );
    expect(
      AppLocalizations.forTag('en').rankTypeLabel(fallback: '必吃榜'),
      'Must-eat ranking',
    );
    expect(
      AppLocalizations.forTag('en').ranksLoadFailed('offline'),
      'Could not load rankings: offline',
    );
    expect(
      AppLocalizations.forTag('en').activitiesLoadFailed('timeout'),
      'Could not load activities: timeout',
    );
    expect(
      AppLocalizations.forTag('en').activityChannelLabel(channel: 4),
      'Activity page',
    );
    expect(
      AppLocalizations.forTag('en').activityTypeLabel(fallback: '专题活动'),
      'Themed campaign',
    );
    expect(
      AppLocalizations.forTag('en').activityTargetTypeLabel(targetType: 4),
      'ranking',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).certificationBadgeLabel(code: 'verified_merchant'),
      'Verified merchant',
    );
    expect(
      AppLocalizations.forTag('en').certificationBadgeLabel(fallback: '本地达人'),
      'Local expert',
    );
    expect(
      AppLocalizations.forTag('en').openTargetFailed('deal', 'offline'),
      'Could not open deal: offline',
    );
    expect(
      AppLocalizations.forTag('en').allNotificationsMarkedRead,
      'All notifications marked as read',
    );
    expect(AppLocalizations.forTag('en').filterUnreadOnly, 'Unread only');
    expect(AppLocalizations.forTag('zh-CN').markAllReadWithCount(3), '全部已读（3）');
    expect(
      AppLocalizations.forTag('en').notificationFollowedYou('Alice'),
      'Alice followed you',
    );
    expect(
      AppLocalizations.forTag('en').notificationTitleReviewLike,
      'Review liked',
    );
    expect(
      AppLocalizations.forTag('en').notificationTitleMention,
      'You were mentioned',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationLikedYourReview(name: 'Alex', preview: 'So useful'),
      'Alex liked your review: So useful',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationRepliedToYou(name: 'Taylor', preview: 'Same here'),
      'Taylor replied to you: Same here',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationRepostedYourPost(name: 'Jordan', title: 'Late-night eats'),
      'Jordan reposted your post "Late-night eats"',
    );
    expect(
      AppLocalizations.forTag('en').notificationMentionedYouInPost(
        name: 'Taylor',
        title: 'Kyoto breakfast',
      ),
      'Taylor mentioned you in the post "Kyoto breakfast"',
    );
    expect(
      AppLocalizations.forTag('en').notificationTopicUpdateContent(
        name: 'Jordan',
        topic: 'Late night eats',
        title: 'Seoul route',
      ),
      'Jordan posted "Seoul route" in #Late night eats',
    );
    expect(
      AppLocalizations.forTag('en').notificationTitleCouponExpired,
      'Coupon expired',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationBanAppealRejectedContent(reason: 'Policy violation'),
      'Your ban appeal was rejected: Policy violation',
    );
    expect(
      AppLocalizations.forTag('en').notificationTitleAccountUnbanned,
      'Account unbanned',
    );
    expect(
      AppLocalizations.forTag('en').banAppealStatusLabel(status: 0),
      'Pending review',
    );
    expect(
      AppLocalizations.forTag('en').banAppealStatusLabel(fallback: '已驳回'),
      'Rejected',
    );
    expect(
      AppLocalizations.forTag('en').banAppealErrorPendingExists,
      'You already have an appeal under review. Wait for the result before submitting another.',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationDirectMessagePreview(name: 'Alex', preview: 'See you soon'),
      'Alex: See you soon',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationPostApprovedContent('Weekend brunch', remark: 'Looks good'),
      '"Weekend brunch" is now public: Looks good',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationCouponExpiringInDays(code: 'CP-DEMO', days: 1),
      'CP-DEMO expires in 1 day',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).notificationCouponRedeemedAt(code: 'CP-DEMO', shop: 'Tea House'),
      'CP-DEMO was redeemed at Tea House',
    );
    expect(
      AppLocalizations.forTag('en').notificationExpertApprovedContent,
      'Your local expert certification was approved',
    );
    expect(AppLocalizations.forTag('en').accountSettings, 'Account settings');
    expect(AppLocalizations.forTag('en').privacyCenter, 'Privacy center');
    expect(AppLocalizations.forTag('zh-CN').growthValueLabel(350), '350 成长值');
    expect(AppLocalizations.forTag('en').communityTitle, 'Community');
    expect(AppLocalizations.forTag('en').createPost, 'Post');
    expect(AppLocalizations.forTag('zh-CN').recommendedTab, '推荐');
    expect(
      AppLocalizations.forTag('en').postMetaStats(likes: 2, comments: 3),
      ' · ❤ 2 · comments 3',
    );
    expect(AppLocalizations.forTag('en').topicPlaza, 'Topics');
    expect(AppLocalizations.forTag('en').hotTab, 'Trending');
    expect(AppLocalizations.forTag('zh-CN').followTopic, '关注话题');
    expect(
      AppLocalizations.forTag('en').topicFollowerCount(12),
      '12 followers',
    );
    expect(AppLocalizations.forTag('en').localCircles, 'Local circles');
    expect(AppLocalizations.forTag('en').joinCircle, 'Join circle');
    expect(
      AppLocalizations.forTag('zh-CN').circleMeta(members: 3, posts: 5),
      '3 位成员 · 5 篇帖子',
    );
    expect(AppLocalizations.forTag('en').directMessages, 'Messages');
    expect(AppLocalizations.forTag('en').blockedUsers, 'Blocked users');
    expect(AppLocalizations.forTag('zh-CN').unblockUser, '解除拉黑');
    expect(
      AppLocalizations.forTag('en').unblockedUser('Alex'),
      'Unblocked Alex',
    );
    expect(AppLocalizations.forTag('en').myOrders, 'Orders');
    expect(AppLocalizations.forTag('en').groupDeals, 'Group deals');
    expect(AppLocalizations.forTag('zh-CN').payPending, '待支付');
    expect(AppLocalizations.forTag('en').buy, 'Buy');
    expect(AppLocalizations.forTag('en').onlineReservation, 'Book online');
    expect(AppLocalizations.forTag('en').myReservations, 'Reservations');
    expect(AppLocalizations.forTag('zh-CN').cancelReservation, '取消预订');
    expect(
      AppLocalizations.forTag('en').reservationStatusLabel(fallback: '已确认'),
      'Confirmed',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).reservationConfirmModeLabel(fallback: '自动确认'),
      'Auto confirm',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).reservationTimelineActionLabel(actionType: 5),
      'Rescheduled by user',
    );
    expect(AppLocalizations.forTag('en').writeReview, 'Write a review');
    expect(AppLocalizations.forTag('en').reviewDetail, 'Review details');
    expect(AppLocalizations.forTag('zh-CN').address, '地址');
    expect(AppLocalizations.forTag('zh-TW').openingHours, '營業時間');
    expect(AppLocalizations.forTag('en').contactPhone, 'Contact phone');
    expect(AppLocalizations.forTag('zh-CN').like, '点赞');
    expect(AppLocalizations.forTag('en').login, 'Sign in');
    expect(AppLocalizations.forTag('en').registerAccount, 'Create account');
    expect(AppLocalizations.forTag('zh-CN').banAppeal, '封禁申诉');
    expect(AppLocalizations.forTag('en').privacyCenter, 'Privacy center');
    expect(AppLocalizations.forTag('en').accountSettings, 'Account settings');
    expect(AppLocalizations.forTag('zh-CN').exportModuleAccount, '账号数据');
    expect(AppLocalizations.forTag('zh-CN').privacyHero, '你的数据，由你说了算');
    expect(AppLocalizations.forTag('en').downloadZip, 'Download ZIP');
    expect(AppLocalizations.forTag('zh-CN').exportTaskTitle(7), '任务 #7');
    expect(
      AppLocalizations.forTag('en').exportDailyLimit(3),
      'Up to 3 times per day',
    );
    expect(AppLocalizations.forTag('zh-CN').applicationReason, '申请理由');
    expect(AppLocalizations.forTag('en').balanceAfterLabel(95), 'Balance 95');
    expect(
      AppLocalizations.forTag('en').auditStatusLabel(fallback: '待审核'),
      'Pending review',
    );
    expect(
      AppLocalizations.forTag('en').privacyExportTaskStatusLabel(2),
      'Ready to download',
    );
    expect(
      AppLocalizations.forTag('en').couponStatusLabel(fallback: '待使用'),
      'Available',
    );
    expect(
      AppLocalizations.forTag('en').refundStatusLabel(fallback: '待审核'),
      'Pending review',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).growthRecordActionLabel('review_create', fallback: '发布点评'),
      'Review published',
    );
    expect(
      AppLocalizations.forTag(
        'zh-CN',
      ).growthRecordActionLabel('review_create', fallback: '完善资料'),
      '完善资料',
    );
    expect(AppLocalizations.forTag('en').anonymousUser, 'Anonymous user');
    expect(AppLocalizations.forTag('en').browseViewCount(2), 'Viewed 2 times');
    expect(
      AppLocalizations.forTag(
        'en',
      ).averageSpendLabel(currency: 'EUR', amount: '19'),
      'Avg spend EUR 19',
    );
    expect(
      AppLocalizations.forTag('en').realPaymentUnavailable,
      'Real payment is not configured. The client will not fake a successful payment.',
    );
    expect(AppLocalizations.forTag('zh-CN').directMessageUser, '私信用户');
    expect(
      AppLocalizations.forTag('en').expertCertificationUpdatedNotice,
      'Local expert certification status updated',
    );
    expect(AppLocalizations.forTag('zh-CN').deleteBrowseHistoryTooltip, '删除足迹');
  });

  test('delegate supports every configured app locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      expect(AppLocalizations.delegate.isSupported(locale), isTrue);
      final strings = await AppLocalizations.delegate.load(locale);
      expect(strings.searchTitle, isNotEmpty);
      expect(strings.cityRankings, isNotEmpty);
      expect(strings.activities, isNotEmpty);
      expect(strings.rankDetailTitle, isNotEmpty);
      expect(strings.activityDetailTitle, isNotEmpty);
    }
  });
}
