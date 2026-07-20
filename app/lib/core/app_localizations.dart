class AppLocalizations {
  const AppLocalizations._(this.tag, this._values);
  final String tag;
  final Map<String, String> _values;

  static const _simplified = {
    'homeTitle': '本地生活',
    'searchHint': '搜索餐厅、超市和生活服务',
    'featured': '附近推荐',
    'profile': '我的',
  };
  static const _traditional = {
    'homeTitle': '在地生活',
    'searchHint': '搜尋餐廳、超市和生活服務',
    'featured': '附近推薦',
    'profile': '我的',
  };
  static const _english = {
    'homeTitle': 'Local life',
    'searchHint': 'Search restaurants, supermarkets and services',
    'featured': 'Featured near you',
    'profile': 'Me',
  };

  factory AppLocalizations.forTag(String tag) {
    if (tag.toLowerCase().startsWith('zh-tw') ||
        tag.toLowerCase().startsWith('zh-hk')) {
      return AppLocalizations._(tag, _traditional);
    }
    if (tag.toLowerCase().startsWith('zh')) {
      return AppLocalizations._(tag, _simplified);
    }
    return AppLocalizations._(tag, _english);
  }

  String get homeTitle => _values['homeTitle']!;
  String get searchHint => _values['searchHint']!;
  String get featured => _values['featured']!;
  String get profile => _values['profile']!;
}
