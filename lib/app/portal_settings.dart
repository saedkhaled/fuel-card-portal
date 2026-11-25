import 'package:flutter/material.dart';

import 'demo_preferences.dart';

class PortalSettings extends ChangeNotifier {
  PortalSettings(this.preferences, {required String? language})
    : _locale = Locale(language == 'en' ? 'en' : 'ar');

  static const languageKey = 'demo.language';

  final DemoPreferences preferences;
  Locale _locale;
  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    await preferences.write(languageKey, locale.languageCode);
    _locale = locale;
    notifyListeners();
  }
}
