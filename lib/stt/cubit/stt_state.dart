import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/state_logging_mixin.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttState with StateLoggingMixin {
  final SpeechToText speech = SpeechToText();
  bool hasSpeech = false;
  List<LocaleName> localeNames = [];
  String systemLocale = PreferencesState.inputLocaleDefault;
  bool initialized = false;

  Future<void> init() async {
    if (initialized) {
      logEvent('Speech already initialized');
      return;
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
        localeNames = await speech.locales();
        final systemLocaleName = await speech.systemLocale();
        systemLocale =
            systemLocaleName?.localeId ?? PreferencesState.inputLocaleDefault;
        logEvent('System locale: $systemLocale');
      }
    } catch (e) {
      log('Exception while initializing speech: $e');
      hasSpeech = false;
      initialized = false;
    }
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
