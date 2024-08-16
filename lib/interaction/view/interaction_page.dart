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
import 'package:inspector_gadget/ai/cubit/ai_cubit.dart';
import 'package:inspector_gadget/camera/cubit/image_cubit.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/heart_rate/heart_rate.dart';
import 'package:inspector_gadget/interaction/cubit/interaction_cubit.dart';
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
import 'package:inspector_gadget/string_ex.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_state.dart';
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
        child: BlocProvider.value(
          value: context.read<AiCubit>(),
          child: BlocProvider.value(
            value: context.read<DatabaseCubit>(),
            child: BlocProvider.value(
              value: context.read<ImageCubit>(),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => HeartRateCubit()),
                  BlocProvider(create: (_) => LocationCubit()),
                ],
                child: InteractionView(interactionMode),
              ),
            ),
          ),
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  AudioRecorder? _audioRecorder;
  SpeechToText? speech;
  TtsState? ttsState;
  MainCubit? mainCubit;
  AiCubit? aiCubit;
  ImageCubit? imageCubit;
  DatabaseCubit? databaseCubit;
  PreferencesState? preferencesState;
  bool areSpeechServicesNative =
      PreferencesState.areSpeechServicesNativeDefault;
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
        debugPrint('STT devices: $devs');

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

  Future<void> _stopRecording(BuildContext context) async {
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
          await _llmPhase(
            context,
            transcripts.merged,
            transcripts.localeMode(),
          );
        }
      } else {
        log('${transcriptionResponse.statusCode} '
            '${transcriptionResponse.reasonPhrase}');
        mainCubit?.setState(MainCubit.errorStateLabel);
      }
    } catch (e) {
      log('Exception during transcription: $e');
      mainCubit?.setState(MainCubit.errorStateLabel);
    }
  }

  /* BEGIN Android native STT utilities */
  Future<void> _resultListener(SpeechRecognitionResult result) async {
    debugPrint('Result listener final: ${result.finalResult}, '
        'words: ${result.recognizedWords}');

    setState(() {
      deferredActionQueue.add(
        DeferredAction(
          ActionKind.speechTranscripted,
          text: result.recognizedWords,
        ),
      );
    });
  }

  void _soundLevelListener(double level) {
    log('audio level change: $level dB');
  }
  /* END Android native STT utilities */

  Future<void> _llmPhase(
    BuildContext context,
    String prompt,
    String locale,
  ) async {
    mainCubit?.setState(MainCubit.llmStateLabel);

    GenerateContentResponse? response;
    var targetLocale = '';
    final inputLocale =
        preferencesState?.inputLocale ?? PreferencesState.inputLocaleDefault;
    final outputLocale =
        preferencesState?.outputLocale ?? PreferencesState.outputLocaleDefault;
    if (widget.interactionMode == InteractionMode.translateMode) {
      final matchedLocale = ttsState?.matchLanguage(locale) ?? outputLocale;
      if (matchedLocale.localeMatch(inputLocale)) {
        targetLocale = outputLocale;
      } else {
        // Also covers matchedLocale == outputLocale
        targetLocale = inputLocale;
      }

      debugPrint('targetLocale: $targetLocale');
      response =
          await aiCubit?.translate(prompt, targetLocale, preferencesState);
    } else {
      targetLocale = inputLocale;
      debugPrint('targetLocale: $targetLocale');
      // final newHeartRate = heartRateCubit?.state ?? 0;
      // if (newHeartRate > 0) {
      //   heartRate = newHeartRate;
      // }

      final loc = await locationCubit?.obtain();
      if (loc != null &&
          (loc.latitude.abs() > 10e-6 || loc.longitude.abs() > 10e-6)) {
        gpsLocation = loc;
      }

      var imagePath = '';
      if (widget.interactionMode == InteractionMode.multiModalMode) {
        imagePath = imageCubit?.state ?? '';
      }

      response = await aiCubit?.chatStep(
        prompt,
        imagePath,
        databaseCubit,
        preferencesState,
        heartRate,
        gpsLocation,
      );
    }

    debugPrint('Final: ${response?.text}');
    if (response == null ||
        response.text.isNullOrWhiteSpace ||
        !context.mounted) {
      mainCubit?.setState(MainCubit.errorStateLabel);
      return;
    }

    if (llmDebugMode) {
      mainCubit?.setState(MainCubit.doneStateLabel);
    } else if (context.mounted) {
      if (areSpeechServicesNative) {
        await _playbackPhase(context, response.text ?? '', null, targetLocale);
      } else {
        await _ttsPhase(context, response.text ?? '', targetLocale);
      }
    }
  }

  Future<void> _ttsPhase(
    BuildContext context,
    String responseText,
    String locale,
  ) async {
    mainCubit?.setState(MainCubit.ttsStateLabel);
    try {
      final ttsFullUrl = Uri.https(functionUrl, ttsEndpoint, {
        'token': chirpToken,
        'language_code': locale,
        'text': responseText,
      });
      final synthetizationResponse = await http.post(ttsFullUrl);

      if (synthetizationResponse.statusCode == 200) {
        if (context.mounted) {
          await _playbackPhase(
            context,
            '',
            synthetizationResponse.bodyBytes,
            locale,
          );
        }
      } else {
        log('${synthetizationResponse.statusCode} '
            '${synthetizationResponse.reasonPhrase}');
        mainCubit?.setState(MainCubit.errorStateLabel);
      }
    } catch (e) {
      log('Error during synthetization: $e');
      mainCubit?.setState(MainCubit.errorStateLabel);
    }
  }

  Future<void> _playbackPhase(
    BuildContext context,
    String responseText,
    Uint8List? audioTrack,
    String locale,
  ) async {
    mainCubit?.setState(MainCubit.playingStateLabel);
    if (responseText.isNotEmpty) {
      if (await ttsState?.setLanguage(locale) ?? false) {
        await ttsState?.speak(
          responseText,
          preferencesState?.volume ?? PreferencesState.volumeDefault,
        );
      }
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
            areSpeechServicesNative =
                preferencesState!.areSpeechServicesNative &&
                    sttState.hasSpeech &&
                    widget.interactionMode != InteractionMode.translateMode;

            ttsState = context.select((TtsCubit cubit) => cubit.state);
            if ((ttsState?.languages.isEmpty ?? false) &&
                sttState.localeNames.isNotEmpty) {
              ttsState?.supplementLanguages(sttState.localeNames);
            }

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
            if (!llmDebugMode) {
              if (areSpeechServicesNative) {
                final options = SpeechListenOptions(
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
            final sttState = context.select((SttCubit cubit) => cubit.state);
            await _llmPhase(
              context,
              deferredAction.text,
              sttState.systemLocale,
            );
        }
      }
    }
  }

  Widget outlinedIcon(
    BuildContext context,
    IconData iconData,
    double iconSize,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Center(
          child:
              Icon(iconData, size: iconSize * 1.1, color: colorScheme.shadow),
        ),
        Center(
          child: Icon(iconData, size: iconSize, color: colorScheme.primary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    mainCubit = context.select((MainCubit cubit) => cubit);
    aiCubit = context.select((AiCubit cubit) => cubit);
    databaseCubit = context.select((DatabaseCubit cubit) => cubit);
    preferencesState = context.select((PreferencesCubit cubit) => cubit.state);
    llmDebugMode =
        preferencesState?.llmDebugMode ?? PreferencesState.llmDebugModeDefault;
    if (llmDebugMode &&
        deferredActionQueue.isNotEmpty &&
        deferredActionQueue.first.actionKind == ActionKind.initialize) {
      deferredActionQueue.add(
        DeferredAction(
          ActionKind.speechTranscripted,
          text: "What is part 121G on O'Reilly Auto Parts?",
        ),
      );
    }

    heartRateCubit = context.select((HeartRateCubit cubit) => cubit);
    locationCubit = context.select((LocationCubit cubit) => cubit);
    imageCubit = context.select((ImageCubit cubit) => cubit);

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
                outlinedIcon(context, Icons.mic_rounded, 200),
              ),
              onTap: () async {
                await _stopRecording(context);
              },
            ),
            // 2: STT phase
            GestureDetector(
              child: AnimateStyles.rotateIn(
                _animationController,
                outlinedIcon(context, Icons.text_fields, 200),
              ),
            ),
            // 3: LLM phase
            GestureDetector(
              child: AnimateStyles.swing(
                _animationController,
                outlinedIcon(context, Icons.science, 200),
              ),
            ),
            // 4: TTS phase: convert LLM response to speech locally or remote
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                outlinedIcon(context, Icons.transcribe, 200),
              ),
            ),
            // 5: Playback phase
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                outlinedIcon(context, Icons.speaker, 200),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // 6: Done phase
            GestureDetector(
              child: AnimateStyles.bounce(
                _animationController,
                outlinedIcon(context, Icons.check, 200),
              ),
              onTap: () {
                deferredActionQueue.add(DeferredAction(ActionKind.initialize));
                mainCubit?.setState(MainCubit.waitingStateLabel);
              },
            ),
            // 7: Error phase
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                outlinedIcon(context, Icons.warning, 200),
              ),
              onTap: () {
                deferredActionQueue.add(DeferredAction(ActionKind.initialize));
                mainCubit?.setState(MainCubit.waitingStateLabel);
              },
            ),
          ],
        ),
      ),
    );
  }
}
