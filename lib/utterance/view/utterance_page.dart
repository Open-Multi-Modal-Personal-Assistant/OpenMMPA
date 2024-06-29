import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/heart_rate/heart_rate.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/location/location.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/utterance/cubit/utterance_cubit.dart';
import 'package:inspector_gadget/utterance/view/constants.dart';
import 'package:inspector_gadget/utterance/view/transcription_list.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class UtterancePage extends StatelessWidget {
  const UtterancePage(this.utteranceMode, {super.key});

  final int utteranceMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HeartRateCubit()),
        BlocProvider(create: (_) => LocationCubit()),
        BlocProvider(create: (_) => SttCubit()),
      ],
      child: UtteranceView(utteranceMode),
    );
  }
}

class UtteranceView extends StatefulWidget {
  const UtteranceView(this.utteranceMode, {super.key});

  final int utteranceMode;

  @override
  State<UtteranceView> createState() => _UtteranceViewState();
}

class _UtteranceViewState extends State<UtteranceView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late AudioRecorder? _audioRecorder;
  late SpeechToText? speech;
  bool areSpeechServicesNative =
      PreferencesState.areSpeechServicesNativeDefault;
  bool areSpeechServicesRemote =
      PreferencesState.areSpeechServicesRemoteDefault;
  bool started = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioRecorder?.dispose();
    _animationController.dispose();
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
      'audio_${DateTime.now().millisecondsSinceEpoch}.pcm',
    );
  }

  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) async {
    final path = await _getPath();

    await recorder.start(config, path: path);
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder?.hasPermission() ?? false) {
        const encoder = AudioEncoder.pcm16bits;

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
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }
  /* END Audio Recorder utilities */

  Future<void> _stopRecording(BuildContext context, MainCubit cubit) async {
    if (areSpeechServicesNative) {
      log('speech stop');
      await speech?.stop();
    } else {
      final path = await _audioRecorder?.stop();
      if (path != null) {
        final recordingFile = File(path);
        final recordingBytes = await recordingFile.readAsBytes();
        if (context.mounted) {
          await _sttPhase(context, cubit, recordingBytes);
        }
      } else {
        final ctx = context;
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(const SnackBar(content: Text('Recording error')));
        }

        cubit.setState(MainCubit.errorStateLabel);
      }
    }
  }

  Future<void> _sttPhase(
    BuildContext context,
    MainCubit cubit,
    Uint8List recordingBytes,
  ) async {
    cubit.setState(MainCubit.sttStateLabel);
    try {
      const queryParameters = '?token=$chirpToken';
      final chirpFullUrl = Uri.parse('$chirpFunction$queryParameters');
      final transcriptionResponse = await http.post(
        chirpFullUrl,
        body: recordingBytes,
      );

      if (transcriptionResponse.statusCode == 200) {
        final transcriptJson =
            json.decode(transcriptionResponse.body) as Map<String, dynamic>;
        final transcripts = Transcriptions.fromJson(transcriptJson);
        if (context.mounted) {
          await _llmPhase(context, cubit, transcripts.merged);
        }
      } else {
        log(transcriptionResponse.toString());
        cubit.setState(MainCubit.errorStateLabel);
      }
    } catch (e) {
      log(e.toString());
      cubit.setState(MainCubit.errorStateLabel);
    }
  }

  /* BEGIN Android native STT utilities */
  Future<void> _resultListener(SpeechRecognitionResult result) async {
    log('Result listener final: ${result.finalResult}, '
        'words: ${result.recognizedWords}');
    final cubit = context.select((MainCubit cubit) => cubit);
    await _llmPhase(context, cubit, result.recognizedWords);
  }

  void _soundLevelListener(double level) {
    // TODO(MrCsabaToth): handle audio level setting
    log('audio level: $level');
  }
  /* END Android native STT utilities */

  Future<void> _llmPhase(
    BuildContext context,
    MainCubit cubit,
    String prompt,
  ) async {
    cubit.setState(MainCubit.llmStateLabel);
    final modelType =
        widget.utteranceMode == UtteranceCubit.quickMode ? 'flash' : 'pro';
    final model = GenerativeModel(
      model: 'gemini-1.5-$modelType-latest',
      apiKey: geminiApiKey,
    );

    // TODO(MrCsabaToth): History: https://github.com/google-gemini/generative-ai-dart/blob/main/samples/dart/bin/advanced_chat.dart
    final chat = model.startChat();
    // TODO(MrCsabaToth): Multi modal call?
    // TODO(MrCsabaToth): Vector DB + embedding for knowledge base
    // TODO(MrCsabaToth): Tools
    final response = await chat.sendMessage(Content.text(prompt));

    debugPrint(response.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!started) {
      started = true;
      final sttState = context.select((SttCubit cubit) => cubit.state);
      speech = sttState.speech;
      final preferencesState =
          context.select((PreferencesCubit cubit) => cubit.state);
      areSpeechServicesNative =
          preferencesState.areSpeechServicesNative && sttState.hasSpeech;
      areSpeechServicesRemote = preferencesState.areSpeechServicesRemote;
      if (areSpeechServicesNative) {
        final options = SpeechListenOptions(
          onDevice: areSpeechServicesRemote,
          // listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: false,
          autoPunctuation: true,
          enableHapticFeedback: true,
        );
        sttState.speech
            .listen(
              onResult: _resultListener,
              listenFor:
                  const Duration(seconds: PreferencesState.listenForDefault),
              pauseFor:
                  const Duration(seconds: PreferencesState.pauseForDefault),
              localeId: sttState.systemLocale,
              onSoundLevelChange: _soundLevelListener,
              listenOptions: options,
            )
            .whenComplete(() => log('speech.listen completed'));
      } else {
        _audioRecorder = AudioRecorder(gzip: areSpeechServicesRemote);
        _startRecording();
      }
    }

    final stateIndex =
        context.select((MainCubit cubit) => cubit.getStateIndex());
    final mainCubit = context.select((MainCubit cubit) => cubit);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.utteranceAppBarTitle)),
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
                await _stopRecording(context, mainCubit);
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
              child: AnimateStyles.shakeY(
                _animationController,
                const Icon(Icons.speaker_phone, size: 220),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // 6: Error phase
            GestureDetector(
              child: AnimateStyles.pulse(
                _animationController,
                const Icon(Icons.warning, size: 220),
              ),
              onTap: () {
                mainCubit.setState(MainCubit.waitingStateLabel);
              },
            ),
          ],
        ),
      ),
    );
  }
}
