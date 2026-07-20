import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:flutter/foundation.dart';

class AppSettings extends ChangeNotifier {
  AppRegion _region = AppRegion.eu;
  String _localeTag = 'zh-CN';

  AppRegion get region => _region;
  String get localeTag => _localeTag;

  void setRegion(AppRegion value) {
    if (_region == value) return;
    _region = value;
    notifyListeners();
  }

  void setLocaleTag(String value) {
    if (_localeTag == value) return;
    _localeTag = value;
    notifyListeners();
  }
}
