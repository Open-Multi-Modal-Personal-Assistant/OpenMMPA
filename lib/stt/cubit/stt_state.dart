import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttState {
  final SpeechToText speech = SpeechToText();
  bool hasSpeech = false;
  List<LocaleName> localeNames = [];
  String systemLocale = PreferencesState.inputLocaleDefault;
  final bool _logEvents = kDebugMode;
  bool initialized = false;

  Future<void> init() async {
    if (initialized) {
      _logEvent('Speech already initialized');
      return;
    }

    _logEvent('Initializing speech');
    try {
      hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _logEvents,
      );
      if (hasSpeech) {
        localeNames = await speech.locales();
        final systemLocaleName = await speech.systemLocale();
        systemLocale =
            systemLocaleName?.localeId ?? PreferencesState.inputLocaleDefault;
      }

      initialized = true;
    } catch (e) {
      log('Exception while initializing speech: $e');
      hasSpeech = false;
    }
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
      'Received error status: $error, listening: ${speech.isListening}',
    );
  }

  void statusListener(String status) {
    _logEvent(
      'Received listener status: $status, listening: ${speech.isListening}',
    );
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      final eventTime = DateTime.now().toIso8601String();
      final logString = '$eventTime $eventDescription';
      debugPrint('$eventTime $eventDescription');
      log(logString, time: DateTime.now());
    }
  }
}
