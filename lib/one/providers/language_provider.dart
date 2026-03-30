import 'package:flutter/material.dart';

enum AppLanguage { english, hindi, marathi }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;

  Locale get locale {
    switch (_language) {
      case AppLanguage.hindi:
        return const Locale('hi');
      case AppLanguage.marathi:
        return const Locale('mr');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }

    _language = language;
    notifyListeners();
  }
}
