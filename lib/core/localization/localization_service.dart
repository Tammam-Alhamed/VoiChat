import 'dart:ui';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'ar.dart';
import 'en.dart';
import 'es.dart';
import 'fr.dart';
import 'it.dart';
import 'ru.dart';

class LocalizationService extends Translations {
  static final _box = GetStorage();

  /// Default language → English
  static const Locale locale = Locale('en', 'US');
  static const Locale fallbackLocale = Locale('en', 'US');

  static const languages = [
    "العربية",
    "English",
    "Español",
    "Français",
    "Italiano",
    "Русский",
  ];

  static const locales = [
    Locale("ar", "SA"),
    Locale("en", "US"),
    Locale("es", "ES"),
    Locale("fr", "FR"),
    Locale("it", "IT"),
    Locale("ru", "RU"),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
    'ar_SA': ar,
    'en_US': en,
    'es_ES': es,
    'fr_FR': fr,
    'it_IT': it,
    'ru_RU': ru,
  };

  void changeLanguage(String language) {
    final locale = _getLocaleFromLanguage(language);
    _box.write('language', language);
    _box.write('locale', '${locale.languageCode}_${locale.countryCode}');
    Get.updateLocale(locale);
  }

  String getLanguage() {
    return _box.read('language') ?? "English";
  }

  static Locale initLanguage() {
    final storedLocale = _box.read('locale');
    if (storedLocale != null) {
      final parts = storedLocale.split('_');
      return Locale(parts[0], parts[1]);
    }
    return locale;
  }

  Locale _getLocaleFromLanguage(String language) {
    final index = languages.indexOf(language);
    return index >= 0 ? locales[index] : locale;
  }
}
