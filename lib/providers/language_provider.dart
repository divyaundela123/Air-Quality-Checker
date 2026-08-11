import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;
  static const _key = 'app_language';

  AppLanguage  get currentLanguage => _language;
  AppStrings   get strings         => AppStrings(_language);
  String       get languageName    => _language.displayName;

  LanguageProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _language = AppLanguage.values.firstWhere(
        (l) => l.code == saved,
        orElse: () => AppLanguage.english,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang.code);
  }
}
