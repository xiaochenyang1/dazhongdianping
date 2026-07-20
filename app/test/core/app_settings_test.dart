import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:dazhongdianping_app/core/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings switch region and locale', () {
    final settings = AppSettings();
    expect(settings.region, AppRegion.eu);
    expect(settings.localeTag, 'zh-CN');

    settings.setRegion(AppRegion.cn);
    settings.setLocaleTag('en');

    expect(settings.region, AppRegion.cn);
    expect(settings.localeTag, 'en');
  });
}
