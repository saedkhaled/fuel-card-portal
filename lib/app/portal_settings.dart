import 'package:flutter/material.dart';

import 'demo_preferences.dart';

class PortalSettings extends ChangeNotifier {
  PortalSettings(this.preferences, this.scenario, {required String? language})
    : _locale = Locale(language == 'en' ? 'en' : 'ar');

  static const languageKey = 'demo.language';

  final DemoPreferences preferences;
  final String scenario;
  Locale _locale;
  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    await preferences.write(languageKey, locale.languageCode);
    _locale = locale;
    notifyListeners();
  }

  String _alertKey(String accountId) => 'demo.$scenario.$accountId.alertPrompt';

  Future<bool> needsAlertPrompt(String accountId) async =>
      await preferences.read(_alertKey(accountId)) == null;

  Future<void> recordAlertChoice(String accountId, {required bool enabled}) =>
      preferences.write(
        _alertKey(accountId),
        enabled ? 'enabled' : 'dismissed',
      );
}
