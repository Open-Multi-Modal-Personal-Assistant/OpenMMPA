import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
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
    if (state is InteractionState) {
      state.setResponseText(content);
    }

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
      final synthResponse = await FirebaseFunctions.instance
          .httpsCallable(ttsFunctionName)
          .call<dynamic>({
        'language_code': locale,
        'text': responseText,
      });

      final synthFileResponse = synthResponse.data as List<Object?>;
      if (synthFileResponse.isNotEmpty && synthFileResponse[0] != null) {
        state.setState(StateBase.playingStateLabel);
        final synthFileName = synthFileResponse[0]! as String;
        log('Synth file name: $synthFileName');
        if (synthFileName.isNotEmpty) {
          final synthBytes =
              await FirebaseStorage.instance.ref(synthFileName).getData();
          if (synthBytes != null && synthBytes.isNotEmpty) {
            player ??= Player();
            final memoryMedia = await Media.memory(synthBytes);
            await player?.open(memoryMedia);
            state.setState(afterStateLabel);
          } else {
            state.errorState();
          }
        } else {
          state.errorState();
        }
      } else {
        state.errorState();
      }
    } on FirebaseFunctionsException catch (e) {
      log('Exception during TTS function call: $e');
      state.errorState();
    } catch (e) {
      log('Error during TTS synth: $e');
      state.errorState();
    }
  }

  bool isAudioPlaying() {
    return player?.state.playing ?? false;
  }

  Future<void> playOrPauseAudio(String filePath) async {
    player ??= Player();
    final buffered = player?.state.buffer.inMilliseconds ?? 0;
    if (buffered <= 0) {
      await player?.open(Media(filePath));
    }

    await player?.playOrPause();
  }

  Future<void> stopAudio() async {
    await player?.stop();
  }

  void disposeTts() {
    player?.dispose();
  }
}
