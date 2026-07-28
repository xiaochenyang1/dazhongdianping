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
