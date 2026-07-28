import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations._(this.tag, this._values);

  final String tag;
  final Map<String, String> _values;

  static const delegate = AppLocalizationsDelegate();
  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('en'),
  ];

  static const _simplified = {
    'homeTitle': '本地生活',
    'searchHint': '搜索餐厅、超市和生活服务',
    'featured': '附近推荐',
    'profile': '我的',
    'homeSubtitle': '发现附近更适合华人的好去处',
    'europe': '欧洲',
    'china': '中国',
    'language': '切换语言',
    'map': '地图',
    'mapsConfigured': 'Google Maps 已配置',
    'mapsUnavailable': 'Google Maps 未配置，仍可按城市和列表浏览。',
    'notifications': '消息通知',
    'account': '个人中心',
    'cityRankings': '城市榜单',
    'activities': '运营活动',
    'placesLoadFailed': '附近门店加载失败',
    'noPlaces': '当前城市暂无门店',
    'homeNavigation': '首页',
    'exploreNavigation': '发现',
    'ordersNavigation': '订单',
    'searchTitle': '搜索结果',
    'searchSuggestionsLoading': '联想加载中...',
    'searchSuggestions': '搜索联想',
    'searchFailed': '搜索失败：{error}',
    'processing': '处理中...',
    'retry': '重试',
    'noMatchingPlaces': '没有匹配的门店',
    'loading': '加载中...',
    'loadMore': '加载更多',
    'loadMoreShopsFailed': '加载更多门店失败：{error}',
    'discoveryFailed': '搜索发现加载失败：{error}',
    'enterKeyword': '输入关键词开始搜索',
    'recentSearches': '最近搜过',
    'clearing': '清空中...',
    'clear': '清空',
    'moreHistory': '更多历史',
    'hotSearches': '当前热词',
    'clearHistoryFailed': '清空搜索历史失败：{error}',
    'removeHistoryFailed': '删除搜索历史失败：{error}',
    'loadMoreHistoryFailed': '加载更多搜索历史失败：{error}',
    'rankDetailTitle': '榜单详情',
    'refreshRanksFailed': '刷新榜单失败：{error}',
    'ranksLoadFailed': '榜单加载失败：{error}',
    'noPublicRanks': '当前区域暂无公开榜单',
    'shopCount': '{count} 家门店',
    'topShop': '榜首 {name}',
    'rankDetailLoadFailed': '榜单详情加载失败：{error}',
    'rankNoShops': '该榜单暂无门店',
    'activityDetailTitle': '活动详情',
    'refreshActivitiesFailed': '刷新活动失败：{error}',
    'activitiesLoadFailed': '活动加载失败：{error}',
    'noOnlineActivities': '当前区域暂无上线活动',
    'resourceCount': '{count} 个资源',
    'activityDetailLoadFailed': '活动详情加载失败：{error}',
    'activityNoItems': '该活动暂无资源项',
    'cannotOpenExternalLink': '无法打开外部链接',
    'openTargetFailed': '{target}打开失败：{error}',
    'targetDeal': '团购',
    'targetTopic': '话题',
    'targetExternalLink': '外部链接',
    'targetResource': '资源',
    'refreshNotificationsFailed': '刷新消息失败：{error}',
    'loadMoreFailed': '加载更多失败：{error}',
    'markReadFailed': '标记已读失败：{error}',
    'allNotificationsMarkedRead': '全部通知已标记为已读',
    'markAllReadFailed': '全部已读失败：{error}',
    'markAllRead': '全部已读',
    'markAllReadWithCount': '全部已读（{count}）',
    'filterAll': '全部',
    'filterUnreadOnly': '只看未读',
    'notificationsLoadFailed': '消息加载失败：{error}',
    'reload': '重新加载',
    'refresh': '刷新',
    'noUnreadNotifications': '暂无未读消息',
    'noNotifications': '暂无消息',
    'continueFindUnread': '继续查找未读消息',
    'unreadBadge': '未读',
    'loggingOut': '退出中...',
    'logout': '退出',
    'profileLoadFailed': '用户资料加载失败：{error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} 积分',
    'growthValueLabel': '{value} 成长值',
    'accountSettings': '账户设置',
    'accountSettingsSubtitle': '资料、绑定账号、修改密码',
    'localExpertCertification': '本地达人认证',
    'localExpertCertificationSubtitle': '提交或重提本地达人申请',
    'growthRecords': '成长值流水',
    'growthRecordsSubtitle': 'Lv.{level} · 成长值 {growth} · 积分 {points}',
    'myMessages': '我的私信',
    'blockedUsers': '黑名单管理',
    'myCircles': '我的圈子',
    'myReviews': '我的点评',
    'myPosts': '我的帖子',
    'myFavorites': '我的收藏',
    'myOrders': '我的订单',
    'myCoupons': '我的券',
    'myReservations': '我的预订',
    'myBrowseHistory': '我的足迹',
    'privacyCenter': '隐私中心',
    'communityTitle': '华人社区',
    'topicPlaza': '话题广场',
    'localCircles': '同城圈子',
    'recommendedTab': '推荐',
    'followingTab': '关注',
    'createPost': '发帖',
    'followingFeedLoginRequired': '登录后查看关注流，关注的人更新时会出现在这里。',
    'loadMorePostsFailed': '加载更多帖子失败：{error}',
    'communityLoadFailed': '社区加载失败：{error}',
    'noCommunityPosts': '暂无帖子',
    'postMetaStats': ' · ❤ {likes} · 评论 {comments}',
  };
  static const _traditional = {
    'homeTitle': '在地生活',
    'searchHint': '搜尋餐廳、超市和生活服務',
    'featured': '附近推薦',
    'profile': '我的',
    'homeSubtitle': '探索附近更適合華人的好去處',
    'europe': '歐洲',
    'china': '中國',
    'language': '切換語言',
    'map': '地圖',
    'mapsConfigured': 'Google Maps 已設定',
    'mapsUnavailable': 'Google Maps 尚未設定，仍可依城市和列表瀏覽。',
    'notifications': '訊息通知',
    'account': '個人中心',
    'cityRankings': '城市排行榜',
    'activities': '精選活動',
    'placesLoadFailed': '附近店家載入失敗',
    'noPlaces': '目前城市暫無店家',
    'homeNavigation': '首頁',
    'exploreNavigation': '探索',
    'ordersNavigation': '訂單',
    'searchTitle': '搜尋結果',
    'searchSuggestionsLoading': '聯想載入中...',
    'searchSuggestions': '搜尋聯想',
    'searchFailed': '搜尋失敗：{error}',
    'processing': '處理中...',
    'retry': '重試',
    'noMatchingPlaces': '沒有符合條件的店家',
    'loading': '載入中...',
    'loadMore': '載入更多',
    'loadMoreShopsFailed': '載入更多店家失敗：{error}',
    'discoveryFailed': '搜尋探索載入失敗：{error}',
    'enterKeyword': '輸入關鍵字開始搜尋',
    'recentSearches': '最近搜尋',
    'clearing': '清除中...',
    'clear': '清除',
    'moreHistory': '更多記錄',
    'hotSearches': '熱門搜尋',
    'clearHistoryFailed': '清除搜尋記錄失敗：{error}',
    'removeHistoryFailed': '刪除搜尋記錄失敗：{error}',
    'loadMoreHistoryFailed': '載入更多搜尋記錄失敗：{error}',
    'rankDetailTitle': '排行榜詳情',
    'refreshRanksFailed': '重新整理排行榜失敗：{error}',
    'ranksLoadFailed': '排行榜載入失敗：{error}',
    'noPublicRanks': '目前區域暫無公開排行榜',
    'shopCount': '{count} 家店家',
    'topShop': '榜首 {name}',
    'rankDetailLoadFailed': '排行榜詳情載入失敗：{error}',
    'rankNoShops': '此排行榜暫無店家',
    'activityDetailTitle': '活動詳情',
    'refreshActivitiesFailed': '重新整理活動失敗：{error}',
    'activitiesLoadFailed': '活動載入失敗：{error}',
    'noOnlineActivities': '目前區域暫無上線活動',
    'resourceCount': '{count} 個資源',
    'activityDetailLoadFailed': '活動詳情載入失敗：{error}',
    'activityNoItems': '此活動暫無資源項',
    'cannotOpenExternalLink': '無法開啟外部連結',
    'openTargetFailed': '{target}開啟失敗：{error}',
    'targetDeal': '團購',
    'targetTopic': '話題',
    'targetExternalLink': '外部連結',
    'targetResource': '資源',
    'refreshNotificationsFailed': '重新整理訊息失敗：{error}',
    'loadMoreFailed': '載入更多失敗：{error}',
    'markReadFailed': '標記已讀失敗：{error}',
    'allNotificationsMarkedRead': '全部通知已標記為已讀',
    'markAllReadFailed': '全部已讀失敗：{error}',
    'markAllRead': '全部已讀',
    'markAllReadWithCount': '全部已讀（{count}）',
    'filterAll': '全部',
    'filterUnreadOnly': '只看未讀',
    'notificationsLoadFailed': '訊息載入失敗：{error}',
    'reload': '重新載入',
    'refresh': '重新整理',
    'noUnreadNotifications': '暫無未讀訊息',
    'noNotifications': '暫無訊息',
    'continueFindUnread': '繼續尋找未讀訊息',
    'unreadBadge': '未讀',
    'loggingOut': '登出中...',
    'logout': '登出',
    'profileLoadFailed': '使用者資料載入失敗：{error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} 積分',
    'growthValueLabel': '{value} 成長值',
    'accountSettings': '帳戶設定',
    'accountSettingsSubtitle': '資料、綁定帳號、修改密碼',
    'localExpertCertification': '在地達人認證',
    'localExpertCertificationSubtitle': '提交或重新提交在地達人申請',
    'growthRecords': '成長值流水',
    'growthRecordsSubtitle': 'Lv.{level} · 成長值 {growth} · 積分 {points}',
    'myMessages': '我的私信',
    'blockedUsers': '黑名單管理',
    'myCircles': '我的圈子',
    'myReviews': '我的評論',
    'myPosts': '我的貼文',
    'myFavorites': '我的收藏',
    'myOrders': '我的訂單',
    'myCoupons': '我的券',
    'myReservations': '我的預訂',
    'myBrowseHistory': '我的足跡',
    'privacyCenter': '隱私中心',
    'communityTitle': '華人社群',
    'topicPlaza': '話題廣場',
    'localCircles': '同城圈子',
    'recommendedTab': '推薦',
    'followingTab': '追蹤',
    'createPost': '發文',
    'followingFeedLoginRequired': '登入後查看追蹤動態，你追蹤的人更新時會出現在這裡。',
    'loadMorePostsFailed': '載入更多貼文失敗：{error}',
    'communityLoadFailed': '社群載入失敗：{error}',
    'noCommunityPosts': '暫無貼文',
    'postMetaStats': ' · ❤ {likes} · 評論 {comments}',
  };
  static const _english = {
    'homeTitle': 'Local life',
    'searchHint': 'Search restaurants, supermarkets and services',
    'featured': 'Featured near you',
    'profile': 'Me',
    'homeSubtitle': 'Chinese-friendly places nearby',
    'europe': 'Europe',
    'china': 'China',
    'language': 'Change language',
    'map': 'Map',
    'mapsConfigured': 'Google Maps is configured',
    'mapsUnavailable':
        'Google Maps is not configured. City and list browsing remain available.',
    'notifications': 'Notifications',
    'account': 'Profile',
    'cityRankings': 'City rankings',
    'activities': 'Activities',
    'placesLoadFailed': 'Could not load nearby places',
    'noPlaces': 'No places in this city yet',
    'homeNavigation': 'Home',
    'exploreNavigation': 'Explore',
    'ordersNavigation': 'Orders',
    'searchTitle': 'Search results',
    'searchSuggestionsLoading': 'Loading suggestions...',
    'searchSuggestions': 'Suggestions',
    'searchFailed': 'Search failed: {error}',
    'processing': 'Working...',
    'retry': 'Retry',
    'noMatchingPlaces': 'No matching places',
    'loading': 'Loading...',
    'loadMore': 'Load more',
    'loadMoreShopsFailed': 'Could not load more places: {error}',
    'discoveryFailed': 'Could not load search discovery: {error}',
    'enterKeyword': 'Enter a keyword to search',
    'recentSearches': 'Recent searches',
    'clearing': 'Clearing...',
    'clear': 'Clear',
    'moreHistory': 'More history',
    'hotSearches': 'Popular searches',
    'clearHistoryFailed': 'Could not clear search history: {error}',
    'removeHistoryFailed': 'Could not remove search history: {error}',
    'loadMoreHistoryFailed': 'Could not load more search history: {error}',
    'rankDetailTitle': 'Ranking details',
    'refreshRanksFailed': 'Could not refresh rankings: {error}',
    'ranksLoadFailed': 'Could not load rankings: {error}',
    'noPublicRanks': 'No public rankings in this region yet',
    'shopCount': '{count} places',
    'topShop': 'Top place: {name}',
    'rankDetailLoadFailed': 'Could not load ranking details: {error}',
    'rankNoShops': 'This ranking has no places yet',
    'activityDetailTitle': 'Activity details',
    'refreshActivitiesFailed': 'Could not refresh activities: {error}',
    'activitiesLoadFailed': 'Could not load activities: {error}',
    'noOnlineActivities': 'No live activities in this region yet',
    'resourceCount': '{count} resources',
    'activityDetailLoadFailed': 'Could not load activity details: {error}',
    'activityNoItems': 'This activity has no resources yet',
    'cannotOpenExternalLink': 'Could not open the external link',
    'openTargetFailed': 'Could not open {target}: {error}',
    'targetDeal': 'deal',
    'targetTopic': 'topic',
    'targetExternalLink': 'external link',
    'targetResource': 'resource',
    'refreshNotificationsFailed': 'Could not refresh notifications: {error}',
    'loadMoreFailed': 'Could not load more: {error}',
    'markReadFailed': 'Could not mark as read: {error}',
    'allNotificationsMarkedRead': 'All notifications marked as read',
    'markAllReadFailed': 'Could not mark all as read: {error}',
    'markAllRead': 'Mark all read',
    'markAllReadWithCount': 'Mark all read ({count})',
    'filterAll': 'All',
    'filterUnreadOnly': 'Unread only',
    'notificationsLoadFailed': 'Could not load notifications: {error}',
    'reload': 'Reload',
    'refresh': 'Refresh',
    'noUnreadNotifications': 'No unread notifications',
    'noNotifications': 'No notifications yet',
    'continueFindUnread': 'Keep looking for unread',
    'unreadBadge': 'Unread',
    'loggingOut': 'Signing out...',
    'logout': 'Sign out',
    'profileLoadFailed': 'Could not load profile: {error}',
    'levelRegionPoints': 'Lv.{level} · {region} · {points} points',
    'growthValueLabel': '{value} growth',
    'accountSettings': 'Account settings',
    'accountSettingsSubtitle': 'Profile, linked accounts, password',
    'localExpertCertification': 'Local expert certification',
    'localExpertCertificationSubtitle': 'Submit or resubmit a local expert application',
    'growthRecords': 'Growth history',
    'growthRecordsSubtitle':
        'Lv.{level} · growth {growth} · points {points}',
    'myMessages': 'Messages',
    'blockedUsers': 'Blocked users',
    'myCircles': 'My circles',
    'myReviews': 'My reviews',
    'myPosts': 'My posts',
    'myFavorites': 'Favorites',
    'myOrders': 'Orders',
    'myCoupons': 'Coupons',
    'myReservations': 'Reservations',
    'myBrowseHistory': 'Browse history',
    'privacyCenter': 'Privacy center',
    'communityTitle': 'Community',
    'topicPlaza': 'Topics',
    'localCircles': 'Local circles',
    'recommendedTab': 'For you',
    'followingTab': 'Following',
    'createPost': 'Post',
    'followingFeedLoginRequired':
        'Sign in to see your following feed. Updates from people you follow will appear here.',
    'loadMorePostsFailed': 'Could not load more posts: {error}',
    'communityLoadFailed': 'Could not load community: {error}',
    'noCommunityPosts': 'No posts yet',
    'postMetaStats': ' · ❤ {likes} · comments {comments}',
  };

  factory AppLocalizations.forTag(String tag) {
    final normalized = tag.toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh-tw') || normalized.startsWith('zh-hk')) {
      return AppLocalizations._(tag, _traditional);
    }
    if (normalized.startsWith('zh')) {
      return AppLocalizations._(tag, _simplified);
    }
    return AppLocalizations._(tag, _english);
  }

  factory AppLocalizations.forLocale(Locale locale) {
    final countryCode = locale.countryCode;
    return AppLocalizations.forTag(
      countryCode == null || countryCode.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}-$countryCode',
    );
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations.forTag('zh-CN');
  }

  String _text(String key) => _values[key]!;
  String _withError(String key, Object error) =>
      _text(key).replaceFirst('{error}', '$error');
  String _withCount(String key, int count) =>
      _text(key).replaceFirst('{count}', '$count');
  String _withName(String key, String name) =>
      _text(key).replaceFirst('{name}', name);

  String get homeTitle => _text('homeTitle');
  String get searchHint => _text('searchHint');
  String get featured => _text('featured');
  String get profile => _text('profile');
  String get homeSubtitle => _text('homeSubtitle');
  String get europe => _text('europe');
  String get china => _text('china');
  String get language => _text('language');
  String get map => _text('map');
  String get mapsConfigured => _text('mapsConfigured');
  String get mapsUnavailable => _text('mapsUnavailable');
  String get notifications => _text('notifications');
  String get account => _text('account');
  String get cityRankings => _text('cityRankings');
  String get activities => _text('activities');
  String get placesLoadFailed => _text('placesLoadFailed');
  String get noPlaces => _text('noPlaces');
  String get homeNavigation => _text('homeNavigation');
  String get exploreNavigation => _text('exploreNavigation');
  String get ordersNavigation => _text('ordersNavigation');
  String get searchTitle => _text('searchTitle');
  String get searchSuggestionsLoading => _text('searchSuggestionsLoading');
  String get searchSuggestions => _text('searchSuggestions');
  String searchFailed(Object error) => _withError('searchFailed', error);
  String get processing => _text('processing');
  String get retry => _text('retry');
  String get noMatchingPlaces => _text('noMatchingPlaces');
  String get loading => _text('loading');
  String get loadMore => _text('loadMore');
  String loadMoreShopsFailed(Object error) =>
      _withError('loadMoreShopsFailed', error);
  String discoveryFailed(Object error) => _withError('discoveryFailed', error);
  String get enterKeyword => _text('enterKeyword');
  String get recentSearches => _text('recentSearches');
  String get clearing => _text('clearing');
  String get clear => _text('clear');
  String get moreHistory => _text('moreHistory');
  String get hotSearches => _text('hotSearches');
  String clearHistoryFailed(Object error) =>
      _withError('clearHistoryFailed', error);
  String removeHistoryFailed(Object error) =>
      _withError('removeHistoryFailed', error);
  String loadMoreHistoryFailed(Object error) =>
      _withError('loadMoreHistoryFailed', error);
  String get rankDetailTitle => _text('rankDetailTitle');
  String refreshRanksFailed(Object error) =>
      _withError('refreshRanksFailed', error);
  String ranksLoadFailed(Object error) => _withError('ranksLoadFailed', error);
  String get noPublicRanks => _text('noPublicRanks');
  String shopCount(int count) => _withCount('shopCount', count);
  String topShop(String name) => _withName('topShop', name);
  String rankDetailLoadFailed(Object error) =>
      _withError('rankDetailLoadFailed', error);
  String get rankNoShops => _text('rankNoShops');
  String get activityDetailTitle => _text('activityDetailTitle');
  String refreshActivitiesFailed(Object error) =>
      _withError('refreshActivitiesFailed', error);
  String activitiesLoadFailed(Object error) =>
      _withError('activitiesLoadFailed', error);
  String get noOnlineActivities => _text('noOnlineActivities');
  String resourceCount(int count) => _withCount('resourceCount', count);
  String activityDetailLoadFailed(Object error) =>
      _withError('activityDetailLoadFailed', error);
  String get activityNoItems => _text('activityNoItems');
  String get cannotOpenExternalLink => _text('cannotOpenExternalLink');
  String openTargetFailed(String target, Object error) => _text(
    'openTargetFailed',
  ).replaceFirst('{target}', target).replaceFirst('{error}', '$error');
  String get targetDeal => _text('targetDeal');
  String get targetTopic => _text('targetTopic');
  String get targetExternalLink => _text('targetExternalLink');
  String get targetResource => _text('targetResource');
  String refreshNotificationsFailed(Object error) =>
      _withError('refreshNotificationsFailed', error);
  String loadMoreFailed(Object error) => _withError('loadMoreFailed', error);
  String markReadFailed(Object error) => _withError('markReadFailed', error);
  String get allNotificationsMarkedRead => _text('allNotificationsMarkedRead');
  String markAllReadFailed(Object error) =>
      _withError('markAllReadFailed', error);
  String get markAllRead => _text('markAllRead');
  String markAllReadWithCount(int count) =>
      _withCount('markAllReadWithCount', count);
  String get filterAll => _text('filterAll');
  String get filterUnreadOnly => _text('filterUnreadOnly');
  String notificationsLoadFailed(Object error) =>
      _withError('notificationsLoadFailed', error);
  String get reload => _text('reload');
  String get refresh => _text('refresh');
  String get noUnreadNotifications => _text('noUnreadNotifications');
  String get noNotifications => _text('noNotifications');
  String get continueFindUnread => _text('continueFindUnread');
  String get unreadBadge => _text('unreadBadge');
  String get loggingOut => _text('loggingOut');
  String get logout => _text('logout');
  String profileLoadFailed(Object error) =>
      _withError('profileLoadFailed', error);
  String levelRegionPoints({
    required int level,
    required String region,
    required int points,
  }) => _text('levelRegionPoints')
      .replaceFirst('{level}', '$level')
      .replaceFirst('{region}', region)
      .replaceFirst('{points}', '$points');
  String growthValueLabel(int value) =>
      _text('growthValueLabel').replaceFirst('{value}', '$value');
  String get accountSettings => _text('accountSettings');
  String get accountSettingsSubtitle => _text('accountSettingsSubtitle');
  String get localExpertCertification => _text('localExpertCertification');
  String get localExpertCertificationSubtitle =>
      _text('localExpertCertificationSubtitle');
  String get growthRecords => _text('growthRecords');
  String growthRecordsSubtitle({
    required int level,
    required int growth,
    required int points,
  }) => _text('growthRecordsSubtitle')
      .replaceFirst('{level}', '$level')
      .replaceFirst('{growth}', '$growth')
      .replaceFirst('{points}', '$points');
  String get myMessages => _text('myMessages');
  String get blockedUsers => _text('blockedUsers');
  String get myCircles => _text('myCircles');
  String get myReviews => _text('myReviews');
  String get myPosts => _text('myPosts');
  String get myFavorites => _text('myFavorites');
  String get myOrders => _text('myOrders');
  String get myCoupons => _text('myCoupons');
  String get myReservations => _text('myReservations');
  String get myBrowseHistory => _text('myBrowseHistory');
  String get privacyCenter => _text('privacyCenter');
  String get communityTitle => _text('communityTitle');
  String get topicPlaza => _text('topicPlaza');
  String get localCircles => _text('localCircles');
  String get recommendedTab => _text('recommendedTab');
  String get followingTab => _text('followingTab');
  String get createPost => _text('createPost');
  String get followingFeedLoginRequired => _text('followingFeedLoginRequired');
  String loadMorePostsFailed(Object error) =>
      _withError('loadMorePostsFailed', error);
  String communityLoadFailed(Object error) =>
      _withError('communityLoadFailed', error);
  String get noCommunityPosts => _text('noCommunityPosts');
  String postMetaStats({required int likes, required int comments}) => _text(
    'postMetaStats',
  ).replaceFirst('{likes}', '$likes').replaceFirst('{comments}', '$comments');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'zh', 'en'}.contains(locale.languageCode.toLowerCase());

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations.forLocale(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
