import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:media_kit/media_kit.dart';

mixin TtsMixin {
  Player? player;

  Future<void> tts(
    BuildContext context,
    String content,
    String locale,
    StateBase state,
    String afterStateLabel,
    PreferencesService preferences, {
    bool areSpeechServicesNative =
        PreferencesService.areSpeechServicesNativeDefault,
  }) async {
    if (areSpeechServicesNative) {
      state.setState(StateBase.playingStateLabel);
      final ttsService = GetIt.I.get<TtsService>();
      if (await ttsService.setLanguage(locale)) {
        await ttsService.speak(content, preferences.volume);
      } else {
        state.errorState();
      }

      state.setState(afterStateLabel);
    } else {
      await ttsPhase(
        context,
        content,
        locale,
        state,
        afterStateLabel,
      );
    }
  }

  Future<void> ttsPhase(
    BuildContext context,
    String responseText,
    String locale,
    StateBase state,
    String afterStateLabel,
  ) async {
    try {
      state.setState(StateBase.ttsStateLabel);
      final ttsFullUrl = Uri.https(functionUrl, ttsEndpoint, {
        'token': chirpToken,
        'language_code': locale,
        'text': responseText,
      });
      final synthetizationResponse = await http.post(ttsFullUrl);

      if (synthetizationResponse.statusCode == 200) {
        if (synthetizationResponse.bodyBytes.isNotEmpty) {
          state.setState(StateBase.playingStateLabel);
          player ??= Player();
          final memoryMedia =
              await Media.memory(synthetizationResponse.bodyBytes);
          await player?.open(memoryMedia);
          state.setState(afterStateLabel);
        } else {
          state.errorState();
        }
      } else {
        log('${synthetizationResponse.statusCode} '
            '${synthetizationResponse.reasonPhrase}');
        state.errorState();
      }
    } catch (e) {
      log('Error during synthetization: $e');
      state.errorState();
    }
  }

  void disposeTts() {
    player?.dispose();
  }
}
