import 'dart:async';
import 'dart:developer';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/ai/service/generated_content_response.dart';
import 'package:inspector_gadget/camera/service/m_file.dart';
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/deferred_action.dart';
import 'package:inspector_gadget/common/string_ex.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/interaction/service/interaction_state.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/outlined_icon.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:inspector_gadget/speech/view/stt_mixin.dart';
import 'package:inspector_gadget/speech/view/tts_mixin.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:watch_it/watch_it.dart';

enum InteractionMode {
  textChat,
  translate,
  imageChat,
}

class InteractionPage extends WatchingStatefulWidget {
  const InteractionPage(
    this.interactionMode, {
    required this.mediaFiles,
    super.key,
  });

  final InteractionMode interactionMode;
  final List<MFile> mediaFiles;
  static const llmTestPrompt = "What is part 121G on O'Reilly Auto Parts?";

  @override
  State<InteractionPage> createState() => InteractionPageState();
}

class InteractionPageState extends State<InteractionPage>
    with SingleTickerProviderStateMixin, SttMixin, TtsMixin {
  late AnimationController _animationController;
  late DatabaseService database;
  late PreferencesService preferences;
  bool areSpeechServicesNative =
      PreferencesService.areSpeechServicesNativeDefault;

  List<DeferredAction> deferredActionQueue = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    GetIt.I.get<InteractionState>().setState(StateBase.waitingStateLabel);
    database = GetIt.I.get<DatabaseService>();
    preferences = GetIt.I.get<PreferencesService>();
    if (preferences.measureHeartRate) {
      GetIt.I.get<HeartRateService>().listenToHeartRate();
    }

    deferredActionQueue.add(DeferredAction(ActionKind.initialize));
  }

  @override
  void dispose() {
    _animationController.dispose();
    // disposeStt();
    // disposeTts();
    super.dispose();
  }

  Future<void> llmPhase(
    BuildContext context,
    String prompt,
    String locale,
  ) async {
    final interactionState = GetIt.I.get<InteractionState>()
      ..setState(StateBase.llmStateLabel);

    GenerateContentResponse? response;
    var targetLocale = '';
    final inputLocale = preferences.inputLocale;
    final outputLocale = preferences.outputLocale;
    final aiService = GetIt.I.get<AiService>();
    if (widget.interactionMode == InteractionMode.translate) {
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

      log('targetLocale: $targetLocale');
      response = await aiService.translate(prompt, locale, targetLocale);
    } else {
      targetLocale = inputLocale;
      log('targetLocale: $targetLocale');

      unawaited(GetIt.I.get<LocationService>().obtain());

      response = await aiService.chatStep(
        prompt,
        widget.mediaFiles,
        widget.interactionMode,
      );
    }

    log('Final: ${response?.text}');
    if (response == null) {
      interactionState.errorState();
      return;
    }

    if (response.strippedText().isEmpty || !context.mounted) {
      interactionState.errorState();
      return;
    }

    if (preferences.llmDebugMode) {
      interactionState.setState(StateBase.doneStateLabel);
    } else if (context.mounted) {
      await tts(
        context,
        response.strippedText(),
        targetLocale,
        GetIt.I.get<InteractionState>(),
        StateBase.doneStateLabel,
        preferences,
        areSpeechServicesNative: areSpeechServicesNative,
      );
    }
  }

  void addToDeferredQueue(DeferredAction deferredAction) {
    deferredActionQueue.add(deferredAction);
    setState(() {});
  }

  Future<void> processDeferredActionQueue(BuildContext context) async {
    if (deferredActionQueue.isNotEmpty) {
      final queueCopy = [...deferredActionQueue];
      deferredActionQueue.clear();
      for (final deferredAction in queueCopy) {
        switch (deferredAction.actionKind) {
          case ActionKind.initialize:
            final sttService = GetIt.I.get<SttService>();
            areSpeechServicesNative = preferences.areSpeechServicesNative &&
                sttService.hasSpeech &&
                widget.interactionMode != InteractionMode.translate;

            final ttsService = GetIt.I.get<TtsService>();
            if (ttsService.languages.isEmpty &&
                sttService.localeNames.isNotEmpty) {
              ttsService.supplementLanguages(sttService.localeNames);
            }

            if (!preferences.llmDebugMode) {
              await stt(
                context,
                preferences.inputLocale,
                GetIt.I.get<InteractionState>(),
                StateBase.browsingStateLabel,
                preferences,
                addToDeferredQueue,
                areSpeechServicesNative: areSpeechServicesNative,
              );
            }

          case ActionKind.speechTranscripted:
            await llmPhase(
              context,
              deferredAction.text,
              deferredAction.locale,
            );
        }
      }
    }
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
          locale: PreferencesService.inputLocaleDefault,
        ),
      );
    }

    processDeferredActionQueue(context);

    final interactionState = GetIt.I.get<InteractionState>();
    final stateIndex = watchPropertyValue((InteractionState s) => s.stateIndex);
    final responseText =
        watchPropertyValue((InteractionState s) => s.responseText);

    final smallHeadline = Theme.of(context).textTheme.headlineSmall;
    final title = switch (stateIndex) {
      0 => Text(l10n.interactionAppBarTitleStart),
      1 => Text(l10n.interactionAppBarTitleStop),
      4 => JumpingText(l10n.interactionAppBarTitleResult, style: smallHeadline),
      5 => JumpingText(l10n.interactionAppBarTitleResult, style: smallHeadline),
      6 => Text(l10n.interactionAppBarTitleResult),
      7 => Text(l10n.interactionAppBarTitleError),
      _ => JumpingText(
          l10n.interactionAppBarTitleProcessing,
          style: smallHeadline,
        ),
    };

    return Scaffold(
      appBar: AppBar(title: title),
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
                outlinedIcon(context, Icons.mic, 200),
              ),
              onTap: () async {
                await stopSpeechRecording(
                  context,
                  interactionState,
                  areSpeechServicesNative: areSpeechServicesNative,
                );
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
              child: responseText.isNotEmptyOrNull
                  ? Text(
                      responseText,
                      style: smallHeadline,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      maxLines: 100,
                    )
                  : AnimateStyles.pulse(
                      _animationController,
                      outlinedIcon(context, Icons.speaker, 200),
                    ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // 6: Done phase
            GestureDetector(
              child: responseText.isNotEmptyOrNull
                  ? Text(
                      responseText,
                      style: smallHeadline,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      maxLines: 100,
                    )
                  : AnimateStyles.bounce(
                      _animationController,
                      outlinedIcon(context, Icons.check, 200),
                    ),
              onTap: () {
                deferredActionQueue.add(DeferredAction(ActionKind.initialize));
                interactionState.setState(StateBase.waitingStateLabel);
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
                interactionState.setState(StateBase.waitingStateLabel);
              },
            ),
          ],
        ),
      ),
    );
  }
}
