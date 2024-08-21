import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/constants.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/interaction/service/deferred_action.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';
import 'package:inspector_gadget/interaction/service/transcription_list.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:inspector_gadget/string_ex.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:watch_it/watch_it.dart';

enum InteractionMode {
  uniModalMode,
  translateMode,
  multiModalMode,
}

class InteractionPage extends StatefulWidget with WatchItStatefulWidgetMixin {
  const InteractionPage(this.interactionMode, {this.imagePath = '', super.key});

  final InteractionMode interactionMode;
  final String imagePath;
  static const llmTestPrompt = "What is part 121G on O'Reilly Auto Parts?";

  @override
  State<InteractionPage> createState() => InteractionPageState();
}

class InteractionPageState extends State<InteractionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late DatabaseService database;
  late PreferencesService preferences;
  bool areSpeechServicesNative =
      PreferencesService.areSpeechServicesNativeDefault;

  AudioRecorder? _audioRecorder;
  List<DeferredAction> deferredActionQueue = [];
  Player? _player;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    GetIt.I
        .get<InteractionState>()
        .setState(InteractionState.waitingStateLabel);
    database = GetIt.I.get<DatabaseService>();
    preferences = GetIt.I.get<PreferencesService>();
    GetIt.I.get<HeartRateService>().listenToHeartRate();

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
      final sttService = GetIt.I.get<SttService>();
      await sttService.speech.stop();
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
        GetIt.I
            .get<InteractionState>()
            .setState(InteractionState.errorStateLabel);
      }
    }
  }

  Future<void> _sttPhase(BuildContext context, List<int> recordingBytes) async {
    final interactionState = GetIt.I.get<InteractionState>()
      ..setState(InteractionState.sttStateLabel);
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
        interactionState.setState(InteractionState.errorStateLabel);
      }
    } catch (e) {
      log('Exception during transcription: $e');
      interactionState.setState(InteractionState.errorStateLabel);
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
    final interactionState = GetIt.I.get<InteractionState>()
      ..setState(InteractionState.llmStateLabel);

    GenerateContentResponse? response;
    var targetLocale = '';
    final inputLocale = preferences.inputLocale;
    final outputLocale = preferences.outputLocale;
    final aiService = GetIt.I.get<AiService>();
    if (widget.interactionMode == InteractionMode.translateMode) {
      final ttsService = GetIt.I.get<TtsService>();
      final matchedLocale = ttsService.matchLanguage(locale);
      if (matchedLocale.localeMatch(inputLocale)) {
        targetLocale = outputLocale;
      } else {
        // Also covers matchedLocale == outputLocale
        if (matchedLocale != outputLocale) {
          preferences.setOutputLocale(matchedLocale);
        }

        targetLocale = inputLocale;
      }

      debugPrint('targetLocale: $targetLocale');
      response = await aiService.translate(prompt, targetLocale);
    } else {
      targetLocale = inputLocale;
      debugPrint('targetLocale: $targetLocale');

      unawaited(GetIt.I.get<LocationService>().obtain());

      var imagePath = '';
      if (widget.interactionMode == InteractionMode.multiModalMode) {
        imagePath = widget.imagePath;
      }

      response = await aiService.chatStep(prompt, imagePath);
    }

    debugPrint('Final: ${response?.text}');
    if (response == null ||
        response.text.isNullOrWhiteSpace ||
        !context.mounted) {
      interactionState.setState(InteractionState.errorStateLabel);
      return;
    }

    if (preferences.llmDebugMode) {
      interactionState.setState(InteractionState.doneStateLabel);
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
    final interactionState = GetIt.I.get<InteractionState>()
      ..setState(InteractionState.ttsStateLabel);
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
        interactionState.setState(InteractionState.errorStateLabel);
      }
    } catch (e) {
      log('Error during synthetization: $e');
      interactionState.setState(InteractionState.errorStateLabel);
    }
  }

  Future<void> _playbackPhase(
    BuildContext context,
    String responseText,
    Uint8List? audioTrack,
    String locale,
  ) async {
    final interactionState = GetIt.I.get<InteractionState>()
      ..setState(InteractionState.playingStateLabel);
    if (responseText.isNotEmpty) {
      final ttsService = GetIt.I.get<TtsService>();
      if (await ttsService.setLanguage(locale)) {
        await ttsService.speak(responseText, preferences.volume);
      }
    } else if (audioTrack.isNotEmptyOrNull) {
      _player ??= Player();
      final memoryMedia = await Media.memory(audioTrack!);
      await _player?.open(memoryMedia);
    } else {
      interactionState.setState(InteractionState.errorStateLabel);
      return;
    }

    interactionState.setState(InteractionState.doneStateLabel);
  }

  Future<void> _processDeferredActionQueue(BuildContext context) async {
    if (deferredActionQueue.isNotEmpty) {
      final queueCopy = [...deferredActionQueue];
      deferredActionQueue.clear();
      for (final deferredAction in queueCopy) {
        switch (deferredAction.actionKind) {
          case ActionKind.initialize:
            GetIt.I
                .get<InteractionState>()
                .setState(InteractionState.recordingStateLabel);

            final sttService = GetIt.I.get<SttService>();
            areSpeechServicesNative = preferences.areSpeechServicesNative &&
                sttService.hasSpeech &&
                widget.interactionMode != InteractionMode.translateMode;

            final ttsService = GetIt.I.get<TtsService>();
            if (ttsService.languages.isEmpty &&
                sttService.localeNames.isNotEmpty) {
              ttsService.supplementLanguages(sttService.localeNames);
            }

            if (!preferences.llmDebugMode) {
              if (areSpeechServicesNative) {
                unawaited(GetIt.I.get<LocationService>().obtain());

                final options = SpeechListenOptions(
                  onDevice: preferences.areNativeSpeechServicesLocal,
                  listenMode: ListenMode.dictation,
                  cancelOnError: true,
                  partialResults: false,
                  autoPunctuation: true,
                  enableHapticFeedback: true,
                );

                await sttService.speech.listen(
                  onResult: _resultListener,
                  listenFor: const Duration(
                    seconds: PreferencesService.listenForDefault,
                  ),
                  pauseFor: const Duration(
                    seconds: PreferencesService.pauseForDefault,
                  ),
                  localeId: preferences.inputLocale,
                  onSoundLevelChange: _soundLevelListener,
                  listenOptions: options,
                );
              } else {
                _audioRecorder = AudioRecorder();
                await _startRecording();
              }
            }

          case ActionKind.speechTranscripted:
            await _llmPhase(
              context,
              deferredAction.text,
              preferences.inputLocale,
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

    if (preferences.llmDebugMode &&
        deferredActionQueue.isNotEmpty &&
        deferredActionQueue.first.actionKind == ActionKind.initialize) {
      deferredActionQueue.add(
        DeferredAction(
          ActionKind.speechTranscripted,
          text: InteractionPage.llmTestPrompt,
        ),
      );
    }

    _processDeferredActionQueue(context);

    final interactionState = GetIt.I.get<InteractionState>();
    final stateIndex = watchPropertyValue((InteractionState s) => s.stateIndex);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.interactionAppBarTitle)),
      body: Center(
        child: IndexedStack(
          index: stateIndex,
          sizing: StackFit.expand,
          children: [
            // 0: Waiting
            AnimateStyles.swing(
              _animationController,
              outlinedIcon(context, Icons.hourglass_bottom, 200),
            ),
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
                interactionState.setState(InteractionState.waitingStateLabel);
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
                interactionState.setState(InteractionState.waitingStateLabel);
              },
            ),
          ],
        ),
      ),
    );
  }
}
