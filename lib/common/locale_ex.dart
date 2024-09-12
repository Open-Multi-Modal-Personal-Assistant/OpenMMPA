import 'package:flutter/material.dart';
import 'package:strings/strings.dart';

extension LocaleEx on Locale {
  static Locale fromPreferences(String localeString) {
    final languageCode = localeString.left(2);
    final right2 = localeString.right(2);
    final countryCode =
        localeString.length > 2 && right2 != languageCode ? right2 : null;

    return Locale(languageCode, countryCode);
  }

  String preferencesString() {
    var str = languageCode;
    if (countryCode != null && countryCode!.isNotEmpty) {
      str += '-$countryCode';
    }

    return str;
  }
}
