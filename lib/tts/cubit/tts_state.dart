import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts/flutter_tts_web.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/state_logging_mixin.dart';

class TTSState with StateLoggingMixin {
  final FlutterTts tts = FlutterTts();
  TtsState engineState = TtsState.stopped;
  // List<LocaleName> localeNames = [];
  String systemLocale = PreferencesState.inputLocaleDefault;
  double volume = 0.5;
  double pitch = 1;
  double rate = 0.5;
  bool initialized = false;

  Future<void> init() async {
    if (initialized) {
      logEvent('TTS already initialized');
      return;
    }

    logEvent('Initializing TTS');
    await _setAwaitOptions();

    if (Platform.isAndroid) {
      await _getDefaultEngine();
      await _getDefaultVoice();
    }

    tts
      ..setStartHandler(() {
        logEvent('TTS Playing');
        engineState = TtsState.playing;
      })
      ..setCompletionHandler(() {
        logEvent('TTS Complete');
        engineState = TtsState.stopped;
      })
      ..setCancelHandler(() {
        logEvent('TTS Cancel');
        engineState = TtsState.stopped;
      })
      ..setPauseHandler(() {
        logEvent('TTS Paused');
        engineState = TtsState.paused;
      })
      ..setContinueHandler(() {
        logEvent('TTS Continued');
        engineState = TtsState.continued;
      })
      ..setErrorHandler((msg) {
        logEvent('TTS error: $msg');
        engineState = TtsState.stopped;
      });
  }

  Future<void> _getDefaultEngine() async {
    final engine = await tts.getDefaultEngine;
    if (engine != null) {
      logEvent('TTS Engine: $engine');
    }
  }

  Future<void> _getDefaultVoice() async {
    final voice = await tts.getDefaultVoice;
    if (voice != null) {
      logEvent('TTS Voice: $voice');
    }
  }

  Future<void> speak(String responseText) async {
    await tts.setVolume(volume);
    await tts.setSpeechRate(rate);
    await tts.setPitch(pitch);

    if (responseText.isNotEmpty) {
      await tts.speak(responseText);
    }
  }

  Future<void> _setAwaitOptions() async {
    await tts.awaitSpeakCompletion(true);
  }

  Future<void> stop() async {
    final result = await tts.stop();
    if (result == 1) {
      engineState = TtsState.stopped;
    }
  }

  Future<void> pause() async {
    final result = await tts.pause();
    if (result == 1) {
      engineState = TtsState.paused;
    }
  }
}
