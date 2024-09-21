import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/ai/service/firebase_mixin.dart';
import 'package:inspector_gadget/camera/service/page_state.dart';
import 'package:inspector_gadget/camera/view/capture_state.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/database/service/history_state.dart';
import 'package:inspector_gadget/database/service/personalization_state.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        log(details.exceptionAsString(), stackTrace: details.stack);
      };

      // Add cross-flavor configuration here
      final preferences = PreferencesService();
      GetIt.I.registerSingleton(preferences);
      await preferences.init();

      GetIt.I.registerLazySingleton(AiService.new);
      GetIt.I.registerLazySingleton(LocationService.new);
      GetIt.I.registerLazySingleton(HeartRateService.new);
      GetIt.I.registerLazySingleton(CaptureState.new);
      GetIt.I.registerLazySingleton(HistoryState.new);
      GetIt.I.registerLazySingleton(PersonalizationState.new);
      GetIt.I.registerLazySingleton(InteractionState.new);

      unawaited(FirebaseMixin.initFirebase());
      final database = DatabaseService();
      GetIt.I.registerSingleton(database);
      unawaited(database.init());
      final sttService = SttService();
      GetIt.I.registerSingleton(sttService);
      unawaited(sttService.init());
      final ttsService = TtsService();
      GetIt.I.registerSingleton(ttsService);
      unawaited(ttsService.init());

      final pageState = PageState(0);
      GetIt.I.registerSingleton(pageState);

      runApp(await builder());
    },
    (error, stack) => error is Exception
        ? log(error.toString(), stackTrace: stack)
        : (error is Error
            ? log(error.toString(), stackTrace: error.stackTrace)
            : log(error.toString())),
  );
}
