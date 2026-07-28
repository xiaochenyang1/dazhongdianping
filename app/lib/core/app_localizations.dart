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
  };
  static const _traditional = {
    'homeTitle': '在地生活',
    'searchHint': '搜尋餐廳、超市和生活服務',
    'featured': '附近推薦',
    'profile': '我的',
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
  };
  static const _english = {
    'homeTitle': 'Local life',
    'searchHint': 'Search restaurants, supermarkets and services',
    'featured': 'Featured near you',
    'profile': 'Me',
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

  String get homeTitle => _text('homeTitle');
  String get searchHint => _text('searchHint');
  String get featured => _text('featured');
  String get profile => _text('profile');
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
