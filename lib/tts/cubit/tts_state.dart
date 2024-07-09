import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:inspector_gadget/state_logging_mixin.dart';

class TTSState with StateLoggingMixin {
  final FlutterTts tts = FlutterTts();
  String engine = '';
  Map<String, String> voice = {};
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
      voice = (await tts.getDefaultVoice as Map<Object?, Object?>)
          .map((key, value) => MapEntry(key! as String, value! as String));
      logEvent('Default TTS Voice: $voice');
      languages = (await tts.getLanguages as List<Object?>)
          .map((o) => o! as String)
          .toList(growable: false);
      logEvent('Languages: $languages');
      engines = (await tts.getEngines as List<Object?>)
          .map((o) => o! as String)
          .toList(growable: false);
      logEvent('Engines: $engines');
    }

    tts
      ..setStartHandler(() {
        logEvent('TTS Playing');
      })
      ..setCompletionHandler(() {
        logEvent('TTS Complete');
      })
      ..setCancelHandler(() {
        logEvent('TTS Cancel');
      })
      ..setPauseHandler(() {
        logEvent('TTS Paused');
      })
      ..setContinueHandler(() {
        logEvent('TTS Continued');
      })
      ..setErrorHandler((msg) {
        logEvent('TTS error: $msg');
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
    logEvent(result == 1 ? 'TTS Stopped' : 'Error while TTS Stop');
  }

  Future<void> pause() async {
    final result = await tts.pause();
    logEvent(result == 1 ? 'TTS Paused' : 'Error while TTS Pause');
  }
}
