import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts/flutter_tts_web.dart';
import 'package:inspector_gadget/state_logging_mixin.dart';

class TTSState with StateLoggingMixin {
  final FlutterTts tts = FlutterTts();
  TtsState engineState = TtsState.stopped;
  String engine = '';
  String voice = '';
  List<String> languages = [];
  String language = '';
  bool isCurrentLanguageInstalled = false;
  List<String> engines = [];
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
      engine = await tts.getDefaultEngine as String;
      logEvent('Default TTS Engine: $engine');
      voice = await tts.getDefaultVoice as String;
      logEvent('Default TTS Voice: $voice');
      languages = await tts.getLanguages as List<String>;
      logEvent('Languages: $languages');
      engines = await tts.getEngines as List<String>;
      logEvent('Engines: $engines');
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

    initialized = true;
  }

  Future<void> setLanguage(String language) async {
    await tts.setLanguage(language);
    if (Platform.isAndroid) {
      isCurrentLanguageInstalled =
          await tts.isLanguageInstalled(language) as bool;
    }
  }

  Future<void> setEngine(String engine) async {
    await tts.setEngine(engine);
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
