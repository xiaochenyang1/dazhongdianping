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
  });

  test('delegate supports every configured app locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      expect(AppLocalizations.delegate.isSupported(locale), isTrue);
      final strings = await AppLocalizations.delegate.load(locale);
      expect(strings.searchTitle, isNotEmpty);
    }
  });
}
