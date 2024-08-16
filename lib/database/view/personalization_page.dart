import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/cubit/ai_cubit.dart';
import 'package:inspector_gadget/constants.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/database/cubit/personalization_cubit.dart';
import 'package:inspector_gadget/database/models/personalization.dart';
import 'package:inspector_gadget/database/view/deferred_action.dart';
import 'package:inspector_gadget/interaction/view/transcription_list.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/stt/cubit/stt_state.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_state.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DatabaseCubit>(),
      child: BlocProvider.value(
        value: context.read<SttCubit>(),
        child: BlocProvider.value(
          value: context.read<TtsCubit>(),
          child: BlocProvider.value(
            value: context.read<PreferencesCubit>(),
            child: BlocProvider.value(
              value: context.read<AiCubit>(),
              child: BlocProvider(
                create: (_) => PersonalizationCubit(),
                child: const PersonalizationView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonalizationView extends StatefulWidget {
  const PersonalizationView({super.key});

  @override
  State<PersonalizationView> createState() => _PersonalizationViewState();
}

class _PersonalizationViewState extends State<PersonalizationView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  int _editCount = 0;
  PreferencesState? preferencesState;
  String inputLocaleId = PreferencesState.inputLocaleDefault;
  AiCubit? aiCubit;
  DatabaseCubit? database;
  PersonalizationCubit? personalizationCubit;

  bool areSpeechServicesNative =
      PreferencesState.areSpeechServicesNativeDefault;
  AudioRecorder? _audioRecorder;
  Player? _player;
  SpeechToText? speech;
  TtsState? ttsState;
  List<DeferredAction> deferredActionQueue = [];

  @override
  void didChangeMetrics() {
    setState(() {
      _editCount++;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addObserver(this);

    deferredActionQueue.add(DeferredAction(ActionKind.initialize));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        personalizationCubit?.setState(PersonalizationCubit.errorStateLabel);
      }
    }
  }

  Future<void> _sttPhase(BuildContext context, List<int> recordingBytes) async {
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
        await embedAndPersistPersonalization(transcripts.merged);
      } else {
        log('${transcriptionResponse.statusCode} '
            '${transcriptionResponse.reasonPhrase}');
        personalizationCubit?.setState(PersonalizationCubit.errorStateLabel);
      }
    } catch (e) {
      log('Exception during transcription: $e');
      personalizationCubit?.setState(PersonalizationCubit.errorStateLabel);
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

  Future<void> embedAndPersistPersonalization(String recorded) async {
    if (recorded.isNotEmpty && database != null) {
      personalizationCubit?.setState(PersonalizationCubit.processingStateLabel);
      final embedding =
          await aiCubit?.obtainEmbedding(recorded, preferencesState) ?? [];
      final personalization = Personalization(recorded, inputLocaleId)
        ..embedding = embedding;
      database!.addUpdatePersonalization(personalization);

      setState(() {
        _editCount++;
      });
    }

    personalizationCubit?.setState(PersonalizationCubit.browsingStateLabel);
  }

  Future<void> _ttsPhase(
    BuildContext context,
    String responseText,
    String locale,
  ) async {
    try {
      final ttsFullUrl = Uri.https(functionUrl, ttsEndpoint, {
        'token': chirpToken,
        'language_code': locale,
        'text': responseText,
      });
      final synthetizationResponse = await http.post(ttsFullUrl);

      if (synthetizationResponse.statusCode == 200) {
        if (synthetizationResponse.bodyBytes.isNotEmpty) {
          _player ??= Player();
          final memoryMedia =
              await Media.memory(synthetizationResponse.bodyBytes);
          await _player?.open(memoryMedia);
          personalizationCubit
              ?.setState(PersonalizationCubit.browsingStateLabel);
        } else {
          personalizationCubit?.setState(PersonalizationCubit.errorStateLabel);
        }
      } else {
        log('${synthetizationResponse.statusCode} '
            '${synthetizationResponse.reasonPhrase}');
        personalizationCubit?.setState(PersonalizationCubit.errorStateLabel);
      }
    } catch (e) {
      log('Error during synthetization: $e');
      personalizationCubit?.setState(PersonalizationCubit.errorStateLabel);
    }
  }

  Future<void> _processDeferredActionQueue(
    BuildContext context,
    SttState sttState,
  ) async {
    if (deferredActionQueue.isNotEmpty) {
      final queueCopy = [...deferredActionQueue];
      deferredActionQueue.clear();
      for (final deferredAction in queueCopy) {
        switch (deferredAction.actionKind) {
          case ActionKind.initialize:
            areSpeechServicesNative =
                preferencesState!.areSpeechServicesNative && sttState.hasSpeech;
          case ActionKind.speechTranscripted:
            await embedAndPersistPersonalization(deferredAction.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    aiCubit = context.select((AiCubit cubit) => cubit);
    preferencesState = context.select((PreferencesCubit cubit) => cubit.state);
    inputLocaleId =
        preferencesState?.inputLocale ?? PreferencesState.inputLocaleDefault;
    database = context.select((DatabaseCubit cubit) => cubit);
    personalizationCubit =
        context.select((PersonalizationCubit cubit) => cubit);
    final stateIndex =
        context.select((PersonalizationCubit cubit) => cubit.getStateIndex());
    final sttState = context.select((SttCubit cubit) => cubit.state);
    final ttsState = context.select((TtsCubit cubit) => cubit.state);

    _processDeferredActionQueue(context, sttState);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalizationAppBarTitle)),
      body: IndexedStack(
        index: stateIndex,
        sizing: StackFit.expand,
        children: [
          // 0: Browsing
          CustomListView(
            key: Key('CLV$_editCount'),
            paginationMode: PaginationMode.page,
            loadingBuilder: (BuildContext context) =>
                const Center(child: CircularProgressIndicator()),
            adapter: ListAdapter(
              fetchItems: (int page, int limit) async {
                final data =
                    await database?.personalizationPaged(page * limit, limit);
                return ListItems(
                  data,
                  reachedToEnd: (data?.length ?? 0) < limit,
                );
              },
            ),
            errorBuilder: (context, error, state) {
              return Column(
                children: [
                  Text(error.toString()),
                  ElevatedButton(
                    onPressed: () => state.loadMore(),
                    child: const Text('Retry'),
                  ),
                ],
              );
            },
            empty: const Center(
              child: Icon(Icons.do_disturb),
            ),
            itemBuilder: (context, _, item) {
              final p13n = item as Personalization;
              return ListTile(
                key: Key('p_${p13n.id}'),
                leading: IconButton(
                  onPressed: () async {
                    personalizationCubit
                        ?.setState(PersonalizationCubit.playingStateLabel);
                    if (areSpeechServicesNative) {
                      if (await ttsState.setLanguage(p13n.locale)) {
                        await ttsState.speak(
                          p13n.content,
                          preferencesState?.volume ??
                              PreferencesState.volumeDefault,
                        );
                      } else {
                        personalizationCubit
                            ?.setState(PersonalizationCubit.errorStateLabel);
                      }

                      personalizationCubit
                          ?.setState(PersonalizationCubit.browsingStateLabel);
                    } else {
                      await _ttsPhase(context, p13n.content, p13n.locale);
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                ),
                subtitle: Text(
                  p13n.content,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  onPressed: () async {
                    final result = await showOkCancelAlertDialog(
                      context: context,
                      message: l10n.areYouSureText,
                      okLabel: l10n.okLabel,
                      cancelLabel: l10n.cancelLabel,
                      defaultType: OkCancelAlertDefaultType.cancel,
                    );

                    if (result == OkCancelResult.ok) {
                      database?.deletePersonalization(p13n.id);
                      setState(() {
                        _editCount++;
                      });
                    }
                  },
                  icon: const Icon(Icons.delete),
                ),
              );
            },
          ),
          // 1: Playback phase
          AnimateStyles.pulse(
            _animationController,
            const Icon(Icons.speaker, size: 220),
          ),
          // 2: Recording phase
          GestureDetector(
            child: AnimateStyles.pulse(
              _animationController,
              const Icon(Icons.mic_rounded, size: 220),
            ),
            onTap: () async {
              await _stopRecording(context);
            },
          ),
          // 3: Processing
          AnimateStyles.rotateIn(
            _animationController,
            const Icon(Icons.text_fields, size: 220),
          ),
          // 7: Error phase
          GestureDetector(
            child: AnimateStyles.pulse(
              _animationController,
              const Icon(Icons.warning, size: 220),
            ),
            onTap: () {
              personalizationCubit
                  ?.setState(PersonalizationCubit.browsingStateLabel);
            },
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () async {
          personalizationCubit
              ?.setState(PersonalizationCubit.recordingStateLabel);

          if (areSpeechServicesNative) {
            final areNativeSpeechServicesLocal =
                preferencesState!.areNativeSpeechServicesLocal;
            final options = SpeechListenOptions(
              onDevice: areNativeSpeechServicesLocal,
              listenMode: ListenMode.dictation,
              cancelOnError: true,
              partialResults: false,
              autoPunctuation: true,
              enableHapticFeedback: true,
            );

            inputLocaleId =
                preferencesState?.inputLocale ?? sttState.systemLocale;
            await sttState.speech.listen(
              onResult: _resultListener,
              listenFor: const Duration(
                seconds: PreferencesState.listenForDefault,
              ),
              pauseFor: const Duration(
                seconds: PreferencesState.pauseForDefault,
              ),
              localeId: inputLocaleId,
              onSoundLevelChange: _soundLevelListener,
              listenOptions: options,
            );
          } else {
            MediaKit.ensureInitialized();
            _audioRecorder = AudioRecorder();
            await _startRecording();
          }
        },
      ),
    );
  }
}
