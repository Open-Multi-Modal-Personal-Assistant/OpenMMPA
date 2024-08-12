import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inspector_gadget/ai/ai.dart';
import 'package:inspector_gadget/camera/cubit/image_cubit.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
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
        // themeMode: ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MainPage(),
      ),
    );
  }
}
