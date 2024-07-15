import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/heart_rate/heart_rate.dart';
import 'package:inspector_gadget/interaction/cubit/interaction_cubit.dart';
import 'package:inspector_gadget/interaction/tools/tools_mixin.dart';
import 'package:inspector_gadget/interaction/view/constants.dart';
import 'package:inspector_gadget/interaction/view/deferred_action.dart';
import 'package:inspector_gadget/interaction/view/transcription_list.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/location/location.dart';
import 'package:inspector_gadget/main/cubit/main_cubit.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_cubit.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class InteractionPage extends StatelessWidget {
  const InteractionPage(this.interactionMode, {super.key});

  final InteractionMode interactionMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<SttCubit>(),
      child: BlocProvider.value(
        value: context.read<TtsCubit>(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => HeartRateCubit()),
            BlocProvider(create: (_) => LocationCubit()),
          ],
          child: InteractionView(interactionMode),
        ),
      ),
    );
  }
}

class InteractionView extends StatefulWidget {
  const InteractionView(this.interactionMode, {super.key});

  final InteractionMode interactionMode;

  @override
  State<InteractionView> createState() => _InteractionViewState();
}

class _InteractionViewState extends State<InteractionView>
    with SingleTickerProviderStateMixin, ToolsMixin {
  late AnimationController _animationController;
  AudioRecorder? _audioRecorder;
  SpeechToText? speech;
  MainCubit? mainCubit;
  PreferencesState? preferencesState;
  bool areSpeechServicesNative =
      PreferencesState.areSpeechServicesNativeDefault;
  bool areSpeechServicesRemote =
      PreferencesState.areSpeechServicesRemoteDefault;
  bool llmDebugMode = PreferencesState.llmDebugModeDefault;
  HeartRateCubit? heartRateCubit;
  int heartRate = 0;
  LocationCubit? locationCubit;
  Location? gpsLocation;
  List<DeferredAction> deferredActionQueue = [];
  Player? _player;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    deferredActionQueue.add(DeferredAction(ActionKind.initialize));
  }

  @override
  void dispose() {
    _audioRecorder?.dispose();
    _animationController.dispose();
    _player?.dispose();
    super.dispose();
  }

  /* BEGIN Audio Recorder utilities */
  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
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

  Future<String> _getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) async {
    final path = await _getPath();

    await recorder.start(config, path: path);
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder?.hasPermission() ?? false) {
        const encoder = AudioEncoder.wav;

        if (!await _isEncoderSupported(encoder)) {
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
      log('Error during start recording $e');
    }
  }
  /* END Audio Recorder utilities */

  Future<void> _stopRecording(BuildContext context) async {
    if (areSpeechServicesNative) {
      log('speech stop');
      await speech?.stop();
    } else {
      final path = await _audioRecorder?.stop();
      if (path != null) {
        final recordingFile = File(path);
        final recordingBytes = await recordingFile.readAsBytes();
        final gzippedPcm = gzip.encode(recordingBytes);
        if (context.mounted) {
          await _sttPhase(context, gzippedPcm);
        }
      } else {
        final ctx = context;
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(const SnackBar(content: Text('Recording error')));
        }

        log('Error during stop recording, path $path');
        mainCubit?.setState(MainCubit.errorStateLabel);
      }
    }
  }

  Future<void> _sttPhase(BuildContext context, List<int> recordingBytes) async {
    mainCubit?.setState(MainCubit.sttStateLabel);
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
        if (context.mounted) {
          await _llmPhase(context, transcripts.merged);
        }
      } else {
        log('${transcriptionResponse.statusCode} '
            '${transcriptionResponse.reasonPhrase}');
        mainCubit?.setState(MainCubit.errorStateLabel);
      }
    } catch (e) {
      log(e.toString());
      mainCubit?.setState(MainCubit.errorStateLabel);
    }
  }

  /* BEGIN Android native STT utilities */
  Future<void> _resultListener(SpeechRecognitionResult result) async {
    log('Result listener final: ${result.finalResult}, '
        'words: ${result.recognizedWords}');

    deferredActionQueue.add(
      DeferredAction(
        ActionKind.speechTranscripted,
        text: result.recognizedWords,
      ),
    );
  }

  void _soundLevelListener(double level) {
    deferredActionQueue.add(
      DeferredAction(
        ActionKind.volumeAdjust,
        integer: (level * 100).toInt(),
        floatingPoint: level,
      ),
    );
    log('audio level: $level');
  }
  /* END Android native STT utilities */

  Future<void> _llmPhase(BuildContext context, String prompt) async {
    mainCubit?.setState(MainCubit.llmStateLabel);
    final fastMode =
        preferencesState?.fastLlmMode ?? PreferencesState.fastLlmModeDefault;
    final modelType = fastMode ? 'flash' : 'pro';
    final tool = getFunctionDeclarations(preferencesState);
    final model = GenerativeModel(
      model: 'gemini-1.5-$modelType',
      apiKey: preferencesState?.geminiApiKey ?? geminiApiKey,
      tools: [tool],
    );
    final chat = model.startChat();

    // TODO(MrCsabaToth): History: https://github.com/google-gemini/generative-ai-dart/blob/main/samples/dart/bin/advanced_chat.dart
    // we still need to roll our own history persistence (there's no sessionId)
    // TODO(MrCsabaToth): Vector DB + embedding for knowledge base
    // Note: ObjectBox supports Vector DB now
    // so we'll use that for both history and RAG
    // TODO(MrCsabaToth): Multi modal call?
    var content = Content.text(prompt);
    var response = await chat.sendMessage(content);

    List<FunctionCall> functionCalls;
    while ((functionCalls = response.functionCalls.toList()).isNotEmpty) {
      final newHeartRate = heartRateCubit?.state ?? 0;
      if (newHeartRate > 0) {
        heartRate = newHeartRate;
      }

      final loc = await locationCubit?.obtain();
      if (loc != null &&
          (loc.latitude.abs() > 10e-6 || loc.longitude.abs() > 10e-6)) {
        gpsLocation = loc;
      }

      final responses = <FunctionResponse>[];
      for (final functionCall in functionCalls) {
        debugPrint('Function call ${functionCall.name}, '
            'params: ${functionCall.args}');
        final response = await dispatchFunctionCall(
          functionCall,
          gpsLocation,
          heartRate,
          preferencesState,
        );
        debugPrint('Function call result ${response?.response}');
        if (response?.response != null) {
          responses.add(response!);
        }
      }

      content = response.candidates.first.content;
      content.parts.addAll(responses);
      response = await chat.sendMessage(content);
    }

    debugPrint('Final: ${response.text}');
    if (response.text.isNullOrWhiteSpace || !context.mounted) {
      mainCubit?.setState(MainCubit.errorStateLabel);
    }

    if (llmDebugMode) {
      mainCubit?.setState(MainCubit.doneStateLabel);
    } else if (context.mounted) {
      if (areSpeechServicesNative) {
        await _playbackPhase(context, response.text!, null);
      } else {
        await _ttsPhase(context, response.text!);
      }
    }
  }

  Future<void> _ttsPhase(BuildContext context, String responseText) async {
    mainCubit?.setState(MainCubit.ttsStateLabel);
    try {
      final ttsFullUrl = Uri.https(functionUrl, ttsEndpoint, {
        'token': chirpToken,
        'languageCode': preferencesState?.outputLocale ?? 'en-US',
        'text': responseText,
      });
      final synthetizationResponse = await http.post(ttsFullUrl);

      if (synthetizationResponse.statusCode == 200) {
        if (context.mounted) {
          await _playbackPhase(context, '', synthetizationResponse.bodyBytes);
        }
      } else {
        log('${synthetizationResponse.statusCode} '
            '${synthetizationResponse.reasonPhrase}');
        mainCubit?.setState(MainCubit.errorStateLabel);
      }
    } catch (e) {
      log(e.toString());
      mainCubit?.setState(MainCubit.errorStateLabel);
    }
  }

  Future<void> _playbackPhase(
    BuildContext context,
    String responseText,
    Uint8List? audioTrack,
  ) async {
    mainCubit?.setState(MainCubit.playingStateLabel);
    if (responseText.isNotEmpty) {
      final ttsState = context.select((TtsCubit cubit) => cubit.state);
      await ttsState.speak(responseText);
    } else if (audioTrack.isNotEmptyOrNull) {
      _player ??= Player();
      final memoryMedia = await Media.memory(audioTrack!);
      await _player?.open(memoryMedia);
    } else {
      mainCubit?.setState(MainCubit.errorStateLabel);
      return;
    }

    mainCubit?.setState(MainCubit.doneStateLabel);
  }

  Future<void> _processDeferredActionQueue(BuildContext context) async {
    if (deferredActionQueue.isNotEmpty) {
      final queueCopy = [...deferredActionQueue];
      deferredActionQueue.clear();
      for (final deferredAction in queueCopy) {
        switch (deferredAction.actionKind) {
          case ActionKind.initialize:
            final sttState = context.select((SttCubit cubit) => cubit.state);

            await heartRateCubit?.listenToHeartRate();
            final newHeartRate = heartRateCubit?.state ?? 0;
            if (newHeartRate > 0) {
              heartRate = newHeartRate;
            }

            final loc = await locationCubit?.obtain();
            if (loc != null &&
                (loc.latitude.abs() > 10e-6 || loc.longitude.abs() > 10e-6)) {
              gpsLocation = loc;
            }

            speech = sttState.speech;
            areSpeechServicesNative =
                preferencesState!.areSpeechServicesNative && sttState.hasSpeech;
            areSpeechServicesRemote = preferencesState!.areSpeechServicesRemote;
            if (!llmDebugMode) {
              if (areSpeechServicesNative) {
                final options = SpeechListenOptions(
                  onDevice: areSpeechServicesRemote,
                  listenMode: ListenMode.dictation,
                  cancelOnError: true,
                  partialResults: false,
                  autoPunctuation: true,
                  enableHapticFeedback: true,
                );
                await sttState.speech.listen(
                  onResult: _resultListener,
                  listenFor: const Duration(
                    seconds: PreferencesState.listenForDefault,
                  ),
                  pauseFor: const Duration(
                    seconds: PreferencesState.pauseForDefault,
                  ),
                  localeId: sttState.systemLocale,
                  onSoundLevelChange: _soundLevelListener,
                  listenOptions: options,
                );
              } else {
                MediaKit.ensureInitialized();
                _audioRecorder = AudioRecorder();
                await _startRecording();
              }
            }

          case ActionKind.volumeAdjust:
            // TODO(MrCsabaToth): Actually set the volume?
            await PreferencesState.prefService
                ?.set(PreferencesState.volumeTag, deferredAction.integer);

          case ActionKind.speechTranscripted:
            await _llmPhase(context, deferredAction.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    mainCubit = context.select((MainCubit cubit) => cubit);
    preferencesState = context.select((PreferencesCubit cubit) => cubit.state);
    llmDebugMode =
        preferencesState?.llmDebugMode ?? PreferencesState.llmDebugModeDefault;
    if (llmDebugMode) {
      deferredActionQueue.add(
        DeferredAction(
          ActionKind.speechTranscripted,
          text: 'What is the weather today?',
        ),
      );
    }

    heartRateCubit = context.select((HeartRateCubit cubit) => cubit);
    locationCubit = context.select((LocationCubit cubit) => cubit);

    _processDeferredActionQueue(context);

    final stateIndex =
        context.select((MainCubit cubit) => cubit.getStateIndex());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interactionAppBarTitle)),
      body: Center(
        child: IndexedStack(
          index: stateIndex,
          sizing: StackFit.expand,
          children: [
            // 0: Waiting
            Container(),
            // 1: Recording phase
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                const Icon(Icons.mic_rounded, size: 220),
              ),
              onTap: () async {
                await _stopRecording(context);
              },
            ),
            // 2: STT phase
            GestureDetector(
              child: AnimateStyles.rotateIn(
                _animationController,
                const Icon(Icons.text_fields, size: 220),
              ),
            ),
            // 3: LLM phase
            GestureDetector(
              child: AnimateStyles.swing(
                _animationController,
                const Icon(Icons.science, size: 220),
              ),
            ),
            // 4: TTS phase: convert LLM response to speech locally or remote
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                const Icon(Icons.transcribe, size: 220),
              ),
            ),
            // 5: Playback phase
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                const Icon(Icons.speaker, size: 220),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // 6: Done phase
            GestureDetector(
              child: AnimateStyles.flipInY(
                _animationController,
                const Icon(Icons.check, size: 220),
              ),
              onTap: () {
                mainCubit?.setState(MainCubit.waitingStateLabel);
              },
            ),
            // 7: Error phase
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                const Icon(Icons.warning, size: 220),
              ),
              onTap: () {
                mainCubit?.setState(MainCubit.waitingStateLabel);
              },
            ),
          ],
        ),
      ),
    );
  }
}
