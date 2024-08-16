import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:inspector_gadget/ai/ai.dart';
import 'package:inspector_gadget/camera/cubit/image_cubit.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/l10n/cubit/locale_cubit.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/locale_ex.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_cubit.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:pref/pref.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AiCubit()),
        BlocProvider(create: (_) => DatabaseCubit()),
        BlocProvider(create: (_) => ImageCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => MainCubit()),
        BlocProvider(create: (_) => PreferencesCubit()),
        BlocProvider(create: (_) => SttCubit()),
        BlocProvider(create: (_) => TtsCubit()),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final mainCubit = context.select((MainCubit cubit) => cubit);
    final sttState = context.select((SttCubit cubit) => cubit.state);
    if (!sttState.initialized) {
      sttState.init();
    }

    final ttsState = context.select((TtsCubit cubit) => cubit.state);
    if (!ttsState.initialized) {
      ttsState.init();
    }

    context.select((DatabaseCubit cubit) => cubit).initialize();

    if (mainCubit.state.name == 'dummy') {
      mainCubit.setState(MainCubit.waitingStateLabel);
    }

    final localizationDelegates = [
      ...AppLocalizations.localizationsDelegates,
      const LocaleNamesLocalizationsDelegate(),
    ];
    final preferencesState =
        context.select((PreferencesCubit cubit) => cubit.state);
    final selectedLocale = LocaleEx.fromPreferences(preferencesState.appLocale);
    final localeCubit = context.select((LocaleCubit cubit) => cubit);
    if (localeCubit.state != selectedLocale) {
      localeCubit.setLanguage(selectedLocale);
    }

    return PrefService(
      service: PreferencesState.prefService!,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FlexThemeData.light(
          scheme: FlexScheme.indigoM3,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        ),
        darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.indigoM3,
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
        ),
        themeMode: preferencesState.themeSelection(),
        localizationsDelegates: localizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: selectedLocale,
        home: const MainPage(),
      ),
    );
  }
}
