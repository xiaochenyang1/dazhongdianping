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
    expect(AppLocalizations.forTag('zh-CN').cityRankings, '城市榜单');
    expect(AppLocalizations.forTag('zh-TW').cityRankings, '城市排行榜');
    expect(AppLocalizations.forTag('en').cityRankings, 'City rankings');
    expect(AppLocalizations.forTag('en').rankDetailTitle, 'Ranking details');
    expect(AppLocalizations.forTag('en').activities, 'Activities');
    expect(
      AppLocalizations.forTag('en').activityDetailTitle,
      'Activity details',
    );
    expect(AppLocalizations.forTag('zh-CN').shopCount(10), '10 家门店');
    expect(AppLocalizations.forTag('en').shopCount(10), '10 places');
    expect(
      AppLocalizations.forTag('en').topShop('Hotpot House'),
      'Top place: Hotpot House',
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
      AppLocalizations.forTag('en').openTargetFailed('deal', 'offline'),
      'Could not open deal: offline',
    );
    expect(
      AppLocalizations.forTag('en').allNotificationsMarkedRead,
      'All notifications marked as read',
    );
    expect(AppLocalizations.forTag('en').filterUnreadOnly, 'Unread only');
    expect(
      AppLocalizations.forTag('zh-CN').markAllReadWithCount(3),
      '全部已读（3）',
    );
    expect(AppLocalizations.forTag('en').accountSettings, 'Account settings');
    expect(AppLocalizations.forTag('en').privacyCenter, 'Privacy center');
    expect(
      AppLocalizations.forTag('zh-CN').growthValueLabel(350),
      '350 成长值',
    );
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
