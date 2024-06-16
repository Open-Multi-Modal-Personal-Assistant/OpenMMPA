import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:pref/pref.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        log(details.exceptionAsString(), stackTrace: details.stack);
      };

      Bloc.observer = const AppBlocObserver();

      // Add cross-flavor configuration here
      PreferencesState.prefService = await PrefServiceShared.init(
        prefix: PreferencesState.prefix,
        defaults: {
          PreferencesState.apiKeyTag: PreferencesState.apiKeyDefault,
          PreferencesState.areSpeechServicesRemoteTag:
              PreferencesState.areSpeechServicesRemoteDefault,
        },
      );

      runApp(await builder());
    },
    (error, stack) => error is Exception
        ? log(error.toString(), stackTrace: stack)
        : (error is Error
            ? log(error.toString(), stackTrace: error.stackTrace)
            : log(error.toString())),
  );
}
