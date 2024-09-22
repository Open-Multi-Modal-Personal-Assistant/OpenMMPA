import 'dart:developer';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/common/deferred_action.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
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

  static String getFileExtension(RecordConfig config) {
    return switch (config.encoder) {
      AudioEncoder.aacLc => 'm4a',
      AudioEncoder.aacEld => 'm4a',
      AudioEncoder.aacHe => 'm4a',
      AudioEncoder.amrNb => 'amr',
      AudioEncoder.amrWb => 'amr',
      AudioEncoder.opus => 'ogg',
      AudioEncoder.flac => 'flac',
      AudioEncoder.wav => 'wav',
      AudioEncoder.pcm16bits => 'pcm',
    };
  }

  Future<String> getPath(RecordConfig config) async {
    final dir = await getApplicationDocumentsDirectory();
    final extension = getFileExtension(config);
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
  }

  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) async {
    final path = await getPath(config);

    await recorder.start(config, path: path);
  }

  Future<void> startRecording({bool forSpeech = true}) async {
    try {
      _audioRecorder ??= AudioRecorder();

      if (await _audioRecorder?.hasPermission() ?? false) {
        // Chirp needs RIFF header, not raw PCM 16bit
        final encoder = forSpeech
            ? AudioEncoder.wav
            : (Platform.isAndroid ? AudioEncoder.opus : AudioEncoder.aacLc);

        if (!await isEncoderSupported(encoder)) {
          return;
        }

        final devs = await _audioRecorder?.listInputDevices() ?? [];
        debugPrint(devs.toString());

        // Going with 44kHz for audio - could be more supported than 22kHz
        // https://github.com/llfbandit/record/issues/345
        // https://learn.microsoft.com/en-us/windows/win32/medfound/aac-encoder
        final config = RecordConfig(
          encoder: encoder,
          numChannels: 1,
          sampleRate: forSpeech ? 8000 : (Platform.isAndroid ? 22050 : 44100),
        );

        await recordFile(_audioRecorder!, config);
      }
    } catch (e) {
      log('Error during start recording (speech $forSpeech): $e');
    }
  }
  /* END Audio Recorder utilities */

  Future<void> stopSpeechRecording(
    BuildContext context,
    StateBase state, {
    bool areSpeechServicesNative =
        PreferencesService.areSpeechServicesNativeDefault,
  }) async {
    if (areSpeechServicesNative) {
      debugPrint('speech stop');
      await speech?.stop();
    } else {
      final recordingFilePath = await _audioRecorder?.stop();
      if (recordingFilePath != null) {
        final recordingFileName = recordingFilePath.split('/').last;
        final recordingFile = File(recordingFilePath);
        final uploadTask = await FirebaseStorage.instance
            .ref(recordingFileName)
            .putFile(recordingFile);
        final recordingUrl = await uploadTask.ref.getDownloadURL();
        log('Uploaded audio: $recordingUrl');
        if (context.mounted) {
          await sttPhase(context, state, recordingFileName);
        }
      } else {
        final ctx = context;
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(const SnackBar(content: Text('Recording error')));
        }

        log('Error during stop speech recording, path $recordingFilePath');
        state.errorState();
      }
    }
  }

  Future<String> stopAudioRecording() async {
    final path = await _audioRecorder?.stop();
    if (path == null || path.isEmpty) {
      log('Error during stop audio recording, path $path');
    }

    return path ?? '';
  }

  Future<void> sttPhase(
    BuildContext context,
    StateBase state,
    String recordingFileName,
  ) async {
    try {
      final transcriptionResponse = await FirebaseFunctions.instance
          .httpsCallable(chirpFunctionName)
          .call<dynamic>({'recording_file_name': recordingFileName});
      final transcriptList = transcriptionResponse.data as List<Object?>;
      final transcripts = Transcriptions.fromJson(transcriptList);
      addToDeferredQueueFunction?.call(
        DeferredAction(
          ActionKind.speechTranscripted,
          text: transcripts.merged,
          locale: transcripts.localeMode(),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      log('Exception during STT function call: $e');
      state.errorState();
    } catch (e) {
      log('Exception during STT transcription: $e');
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
      await startRecording();
    }
  }

  void disposeStt() {
    _audioRecorder?.dispose();
  }
}
