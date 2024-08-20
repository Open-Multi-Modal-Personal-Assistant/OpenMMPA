import 'dart:developer';

import 'package:flutter/foundation.dart';
// import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/state_logging_mixin.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttService with StateLoggingMixin {
  final SpeechToText speech = SpeechToText();
  bool hasSpeech = false;
  List<LocaleName> localeNames = [];
  String systemLocale = PreferencesService.inputLocaleDefault;
  bool initialized = false;

  Future<SttService> init() async {
    if (initialized) {
      logEvent('Speech already initialized');
      return this;
    }

    initialized = true;
    logEvent('Initializing speech');
    try {
      hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: kDebugMode,
      );
      if (hasSpeech) {
        // https://stackoverflow.com/questions/60347425/how-can-i-distinct-a-complex-object-list-in-dart
        final idSet = <String>{};
        for (final locale in await speech.locales()) {
          if (idSet.add(locale.localeId)) {
            localeNames.add(locale);
          }
        }

        localeNames.sort((a, b) => a.name.compareTo(b.name));

        final systemLocaleName = await speech.systemLocale();
        systemLocale =
            systemLocaleName?.localeId ?? PreferencesService.inputLocaleDefault;
        logEvent('System locale: $systemLocale');

        // GetIt.I.signalReady(this);
      }
    } catch (e) {
      log('Exception while initializing speech: $e');
      hasSpeech = false;
      initialized = false;
    }

    return this;
  }

  void errorListener(SpeechRecognitionError error) {
    logEvent(
      'Received error status: $error, listening: ${speech.isListening}',
    );
  }

  void statusListener(String status) {
    logEvent(
      'Received listener status: $status, listening: ${speech.isListening}',
    );
  }
}
