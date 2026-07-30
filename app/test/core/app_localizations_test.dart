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
      AppLocalizations.forTag('en').notificationErrorUnavailable,
      'The notification service is temporarily unavailable.',
    );
    expect(
      AppLocalizations.forTag('en').notificationErrorRefreshUnavailable,
      'Notifications could not be refreshed right now.',
    );
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
      AppLocalizations.forTag('en').authErrorInvalidCredentials,
      'The account or password is incorrect. Check them and try again.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorCodeRateLimited,
      'Verification codes are being sent too often. Wait a bit and try again.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorEmailAlreadyBound,
      'This email is already bound to another account.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorOldPasswordIncorrect,
      'The current password is incorrect.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorCurrentUserNotFound,
      'Your account could not be found. Please sign in again.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorSessionMissing,
      'Your sign-in session is no longer available. Please sign in again.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorUserNotFound,
      'This user could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorConversationMissing,
      'This conversation could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorCannotMessageSelf,
      'You cannot send direct messages to yourself.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorBlockedRelationship,
      'You cannot send a direct message while a block relationship exists.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorCannotBlockSelf,
      'You cannot block yourself.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorReportTargetUnavailable,
      'This report target is unavailable or you do not have access.',
    );
    expect(
      AppLocalizations.forTag('en').messageErrorReportDuplicate,
      'You already reported this target. Do not submit it again.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorProfileNicknameTooLong,
      'Nickname must be 64 characters or fewer.',
    );
    expect(
      AppLocalizations.forTag('en').authErrorProfileUpdateFailed,
      'The profile could not be updated. Try again later.',
    );
    expect(
      AppLocalizations.forTag('en').publicProfileErrorUserNotFound,
      'This user could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').publicProfileErrorSessionMissing,
      'Your sign-in session is no longer available. Please sign in again.',
    );
    expect(
      AppLocalizations.forTag('en').publicProfileErrorCannotFollowSelf,
      'You cannot follow yourself.',
    );
    expect(
      AppLocalizations.forTag('en').userCollectionErrorSessionMissing,
      'Your sign-in session is no longer available. Please sign in again.',
    );
    expect(
      AppLocalizations.forTag('en').growthRecordsErrorSessionMissing,
      'Your sign-in session is no longer available. Please sign in again.',
    );
    expect(
      AppLocalizations.forTag('en').privacyDeleteErrorNoPassword,
      'This account does not have a login password available for verification. Use code verification instead.',
    );
    expect(
      AppLocalizations.forTag('en').privacyDeleteErrorWrongPassword,
      'The current login password is incorrect.',
    );
    expect(
      AppLocalizations.forTag('en').privacyErrorExportLimitReached,
      'Today\'s privacy export quota is already used up. Try again tomorrow.',
    );
    expect(
      AppLocalizations.forTag('en').privacyErrorDeleteTaskPending,
      'You already have a delete request in progress. Finish the current one first.',
    );
    expect(
      AppLocalizations.forTag('en').expertErrorPendingExists,
      'You already have a local expert application under review. Wait for the current result first.',
    );
    expect(
      AppLocalizations.forTag('en').expertErrorAlreadyApproved,
      'You are already a certified local expert. No need to apply again.',
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
    expect(
      AppLocalizations.forTag('en').topicErrorNotFound,
      'This topic could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').topicErrorUnavailable,
      'This topic is unavailable.',
    );
    expect(
      AppLocalizations.forTag('en').topicErrorFollowFailed,
      'The follow request could not be completed.',
    );
    expect(AppLocalizations.forTag('en').localCircles, 'Local circles');
    expect(
      AppLocalizations.forTag('en').circleErrorJoinedOnlyLoginRequired,
      'Sign in to see the circles you joined.',
    );
    expect(
      AppLocalizations.forTag('en').circleErrorNotFound,
      'This circle could not be found.',
    );
    expect(AppLocalizations.forTag('en').joinCircle, 'Join circle');
    expect(
      AppLocalizations.forTag('zh-CN').circleMeta(members: 3, posts: 5),
      '3 位成员 · 5 篇帖子',
    );
    expect(
      AppLocalizations.forTag('en').communityErrorPostNotFound,
      'This post could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').communityErrorReportDuplicate,
      'You already reported this post. Do not submit it again.',
    );
    expect(
      AppLocalizations.forTag('en').communityErrorReplyTargetMissing,
      'The comment you are replying to could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').communityErrorJoinCircleToPost,
      'Join the circle before posting.',
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
    expect(
      AppLocalizations.forTag('en').tradeErrorDealNotFound,
      'This deal could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorDealExpired,
      'This deal has expired.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorDealOutOfStock,
      'This deal is sold out.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorOrderNotFound,
      'This order could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorOrderPaymentUnavailable,
      'This order cannot be paid right now.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorOrderCancelUnavailable,
      'This order cannot be canceled right now.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorOrderRefundUnavailable,
      'This order cannot be refunded right now.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorRefundUsedCoupons,
      'This order includes redeemed coupons, so a full refund is unavailable.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorRefundExists,
      'A refund request already exists for this order.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorCouponCodeRequired,
      'Enter a coupon code.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorCouponNotFound,
      'This coupon could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').tradeErrorPaymentChannelUnavailable,
      'Payment services are not configured yet.',
    );
    expect(
      AppLocalizations.forTag('en').browseErrorShopNotFound,
      'This place could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').browseErrorSearchHistoryNotFound,
      'This search history item could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').browseErrorInvalidShopId,
      'The place id is invalid.',
    );
    expect(
      AppLocalizations.forTag('en').browseErrorUnsupportedReviewSort,
      'This review sort option is unsupported.',
    );
    expect(
      AppLocalizations.forTag('en').browseErrorUnsupportedFavoriteTarget,
      'This favorite target type is unsupported.',
    );
    expect(AppLocalizations.forTag('en').onlineReservation, 'Book online');
    expect(AppLocalizations.forTag('en').myReservations, 'Reservations');
    expect(AppLocalizations.forTag('zh-CN').cancelReservation, '取消预订');
    expect(
      AppLocalizations.forTag('en').reservationErrorInvalidPeopleCount,
      'Guest count must be at least 1.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorSlotOrTimeRequired,
      'Select a reservation slot first.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorSlotCapacityUnavailable,
      'This time slot no longer has enough availability.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorCancelDeadlinePassed,
      'The cancellation window has passed.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorCancelUnavailable,
      'This reservation cannot be canceled right now.',
    );
    expect(
      AppLocalizations.forTag(
        'en',
      ).reservationErrorRescheduleSlotCapacityUnavailable,
      'The new time slot no longer has enough availability.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorRescheduleUnavailable,
      'This reservation cannot be rescheduled right now.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorSlotNotFound,
      'This reservation slot could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').reservationErrorNotFound,
      'This reservation could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').reservationStatusLabel(fallback: '已确认'),
      'Confirmed',
    );
    expect(
      AppLocalizations.forTag('en').rankErrorNotFound,
      'This ranking could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').rankErrorInvalidType,
      'This ranking type is unsupported.',
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
    expect(
      AppLocalizations.forTag('en').activityErrorNotFoundOrOffline,
      'This activity could not be found or is no longer online.',
    );
    expect(AppLocalizations.forTag('en').writeReview, 'Write a review');
    expect(AppLocalizations.forTag('en').reviewDetail, 'Review details');
    expect(
      AppLocalizations.forTag('en').reviewErrorNotFound,
      'This review could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').reviewErrorReportDuplicate,
      'You already reported this review. Do not submit it again.',
    );
    expect(
      AppLocalizations.forTag('en').reviewErrorReplyTargetMissing,
      'The comment you are replying to could not be found.',
    );
    expect(
      AppLocalizations.forTag('en').reviewErrorUserUnavailable,
      'Your account is currently unavailable.',
    );
    expect(
      AppLocalizations.forTag('en').reviewErrorShopUnavailable,
      'This place is unavailable for reviews.',
    );
    expect(
      AppLocalizations.forTag('en').reviewErrorShopImmutable,
      'The place for this review cannot be changed.',
    );
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
