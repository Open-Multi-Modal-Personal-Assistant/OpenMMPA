import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/common/deferred_action.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/transcription_list.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef AddToDeferredQueue = void Function(DeferredAction deferredAction);

mixin SttMixin {
  AudioRecorder? _audioRecorder;
  SpeechToText? speech;
  String sttInputLocale = PreferencesService.inputLocaleDefault;
  AddToDeferredQueue? addToDeferredQueueFunction;

  /* BEGIN Audio Recorder utilities */
  Future<bool> isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await _audioRecorder?.isEncoderSupported(
          encoder,
        ) ??
        false;

    if (!isSupported) {
      debugPrint('${encoder.name} is not supported on this platform.');
      debugPrint('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await _audioRecorder?.isEncoderSupported(e) ?? false) {
          debugPrint('- ${encoder.name}');
        }
      }
    }

    return isSupported;
  }

  Future<String> getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) async {
    final path = await getPath();

    await recorder.start(config, path: path);
  }

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder?.hasPermission() ?? false) {
        const encoder = AudioEncoder.wav;

        if (!await isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder?.listInputDevices() ?? [];
        debugPrint(devs.toString());

        const config = RecordConfig(
          encoder: encoder,
          numChannels: 1,
          sampleRate: 8000,
        );

        await recordFile(_audioRecorder!, config);
      }
    } catch (e) {
      log('Error during start recording: $e');
    }
  }
  /* END Audio Recorder utilities */

  Future<void> stopRecording(
    BuildContext context,
    StateBase state, {
    bool areSpeechServicesNative =
        PreferencesService.areSpeechServicesNativeDefault,
  }) async {
    if (areSpeechServicesNative) {
      debugPrint('speech stop');
      await speech?.stop();
    } else {
      final path = await _audioRecorder?.stop();
      if (path != null) {
        final recordingFile = File(path);
        final recordingBytes = await recordingFile.readAsBytes();
        final gzippedPcm = gzip.encode(recordingBytes);
        if (context.mounted) {
          await sttPhase(context, state, gzippedPcm);
        }
      } else {
        final ctx = context;
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(const SnackBar(content: Text('Recording error')));
        }

        log('Error during stop recording, path $path');
        state.errorState();
      }
    }
  }

  Future<void> sttPhase(
    BuildContext context,
    StateBase state,
    List<int> recordingBytes,
  ) async {
    try {
      final sttFullUrl =
          Uri.https(functionUrl, sttEndpoint, {'token': chirpToken});
      final transcriptionResponse = await http.post(
        sttFullUrl,
        body: recordingBytes,
      );

      if (transcriptionResponse.statusCode == 200) {
        final transcriptJson =
            json.decode(transcriptionResponse.body) as List<dynamic>;
        final transcripts = Transcriptions.fromJson(transcriptJson);
        addToDeferredQueueFunction?.call(
          DeferredAction(
            ActionKind.speechTranscripted,
            text: transcripts.merged,
            locale: transcripts.localeMode(),
          ),
        );
      } else {
        log('${transcriptionResponse.statusCode} '
            '${transcriptionResponse.reasonPhrase}');
        state.errorState();
      }
    } catch (e) {
      log('Exception during transcription: $e');
      state.errorState();
    }
  }

  /* BEGIN Android native STT utilities */
  Future<void> resultListener(SpeechRecognitionResult result) async {
    debugPrint('Result listener final: ${result.finalResult}, '
        'words: ${result.recognizedWords}');

    addToDeferredQueueFunction?.call(
      DeferredAction(
        ActionKind.speechTranscripted,
        text: result.recognizedWords,
        locale: sttInputLocale,
      ),
    );
  }

  void soundLevelListener(double level) {
    log('audio level change: $level dB');
  }
  /* END Android native STT utilities */

  Future<void> stt(
    BuildContext context,
    String inputLocale,
    StateBase state,
    String afterStateLabel,
    PreferencesService preferences,
    AddToDeferredQueue addToQueue, {
    bool areSpeechServicesNative =
        PreferencesService.areSpeechServicesNativeDefault,
  }) async {
    state.setState(StateBase.recordingStateLabel);
    sttInputLocale = inputLocale;
    addToDeferredQueueFunction = addToQueue;

    if (areSpeechServicesNative) {
      final options = SpeechListenOptions(
        onDevice: preferences.areNativeSpeechServicesLocal,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: false,
        autoPunctuation: true,
        enableHapticFeedback: true,
      );

      final sttService = GetIt.I.get<SttService>();
      await sttService.speech.listen(
        onResult: resultListener,
        listenFor: const Duration(
          seconds: PreferencesService.listenForDefault,
        ),
        pauseFor: const Duration(
          seconds: PreferencesService.pauseForDefault,
        ),
        localeId: inputLocale,
        onSoundLevelChange: soundLevelListener,
        listenOptions: options,
      );
    } else {
      _audioRecorder = AudioRecorder();
      await startRecording();
    }
  }

  void disposeStt() {
    _audioRecorder?.dispose();
  }
}
