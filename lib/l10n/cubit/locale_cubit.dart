import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:inspector_gadget/locale_ex.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit()
      : super(LocaleEx.fromPreferences(PreferencesState.appLocaleDefault));

  void setLanguage(Locale locale) {
    emit(locale);
  }
}
