import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/constants.dart';
import 'package:inspector_gadget/database/models/personalization.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/database/service/deferred_action.dart';
import 'package:inspector_gadget/database/service/personalization_state.dart';
import 'package:inspector_gadget/interaction/service/transcription_list.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/secrets.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:watch_it/watch_it.dart';

class PersonalizationPage extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => PersonalizationPageState();
}

class PersonalizationPageState extends State<PersonalizationPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  int _editCount = 0;
  late DatabaseService database;
  late PreferencesService preferences;
  String inputLocaleId = PreferencesService.inputLocaleDefault;
  bool areSpeechServicesNative =
      PreferencesService.areSpeechServicesNativeDefault;
  AudioRecorder? _audioRecorder;
  Player? _player;
  SpeechToText? speech;
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

    GetIt.I
        .get<PersonalizationState>()
        .setState(PersonalizationState.browsingStateLabel);
    database = GetIt.I.get<DatabaseService>();
    preferences = GetIt.I.get<PreferencesService>();

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
        GetIt.I
            .get<PersonalizationState>()
            .setState(PersonalizationState.errorStateLabel);
      }
    }
  }

  Future<void> _sttPhase(BuildContext context, List<int> recordingBytes) async {
    final personalizationViewState = GetIt.I.get<PersonalizationState>();
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
        personalizationViewState.setState(PersonalizationState.errorStateLabel);
      }
    } catch (e) {
      log('Exception during transcription: $e');
      personalizationViewState.setState(PersonalizationState.errorStateLabel);
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
    final personalizationViewState = GetIt.I.get<PersonalizationState>();
    if (recorded.isNotEmpty) {
      personalizationViewState
          .setState(PersonalizationState.processingStateLabel);
      final aiService = GetIt.I.get<AiService>();
      final embedding = await aiService.obtainEmbedding(recorded);
      final personalization = Personalization(recorded, inputLocaleId)
        ..embedding = embedding;
      database.addUpdatePersonalization(personalization);

      setState(() {
        _editCount++;
      });
    }

    personalizationViewState.setState(PersonalizationState.browsingStateLabel);
  }

  Future<void> _ttsPhase(
    BuildContext context,
    String responseText,
    String locale,
  ) async {
    final personalizationViewState = GetIt.I.get<PersonalizationState>();
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
          personalizationViewState
              .setState(PersonalizationState.browsingStateLabel);
        } else {
          personalizationViewState
              .setState(PersonalizationState.errorStateLabel);
        }
      } else {
        log('${synthetizationResponse.statusCode} '
            '${synthetizationResponse.reasonPhrase}');
        personalizationViewState.setState(PersonalizationState.errorStateLabel);
      }
    } catch (e) {
      log('Error during synthetization: $e');
      personalizationViewState.setState(PersonalizationState.errorStateLabel);
    }
  }

  Future<void> _processDeferredActionQueue(BuildContext context) async {
    if (deferredActionQueue.isNotEmpty) {
      final queueCopy = [...deferredActionQueue];
      deferredActionQueue.clear();
      for (final deferredAction in queueCopy) {
        switch (deferredAction.actionKind) {
          case ActionKind.initialize:
            final sttService = GetIt.I.get<SttService>();
            areSpeechServicesNative =
                preferences.areSpeechServicesNative && sttService.hasSpeech;
          case ActionKind.speechTranscripted:
            await embedAndPersistPersonalization(deferredAction.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    inputLocaleId = preferences.inputLocale;
    final stateIndex =
        watchPropertyValue((PersonalizationState s) => s.stateIndex);
    final personalizationViewState = GetIt.I.get<PersonalizationState>();

    _processDeferredActionQueue(context);

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
                    await database.personalizationPaged(page * limit, limit);
                return ListItems(
                  data,
                  reachedToEnd: data.length < limit,
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
                    personalizationViewState
                        .setState(PersonalizationState.playingStateLabel);
                    if (areSpeechServicesNative) {
                      final ttsService = GetIt.I.get<TtsService>();
                      if (await ttsService.setLanguage(p13n.locale)) {
                        await ttsService.speak(
                          p13n.content,
                          preferences.volume,
                        );
                      } else {
                        personalizationViewState
                            .setState(PersonalizationState.errorStateLabel);
                      }

                      personalizationViewState
                          .setState(PersonalizationState.browsingStateLabel);
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
                      database.deletePersonalization(p13n.id);
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
              personalizationViewState
                  .setState(PersonalizationState.browsingStateLabel);
            },
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () async {
          personalizationViewState
              .setState(PersonalizationState.recordingStateLabel);
          if (areSpeechServicesNative) {
            final options = SpeechListenOptions(
              onDevice: preferences.areNativeSpeechServicesLocal,
              listenMode: ListenMode.dictation,
              cancelOnError: true,
              partialResults: false,
              autoPunctuation: true,
              enableHapticFeedback: true,
            );

            inputLocaleId = preferences.inputLocale;
            final sttService = GetIt.I.get<SttService>();
            await sttService.speech.listen(
              onResult: _resultListener,
              listenFor: const Duration(
                seconds: PreferencesService.listenForDefault,
              ),
              pauseFor: const Duration(
                seconds: PreferencesService.pauseForDefault,
              ),
              localeId: inputLocaleId,
              onSoundLevelChange: _soundLevelListener,
              listenOptions: options,
            );
          } else {
            _audioRecorder = AudioRecorder();
            await _startRecording();
          }
        },
      ),
    );
  }
}
