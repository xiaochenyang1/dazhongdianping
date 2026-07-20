import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizations provide simplified, traditional and English text', () {
    expect(AppLocalizations.forTag('zh-CN').homeTitle, '本地生活');
    expect(AppLocalizations.forTag('zh-TW').homeTitle, '在地生活');
    expect(AppLocalizations.forTag('en').homeTitle, 'Local life');
  });
}
