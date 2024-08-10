import 'dart:developer';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/ai/cubit/ai_cubit.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/database/cubit/personalization_cubit.dart';
import 'package:inspector_gadget/database/models/personalization.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  /* BEGIN Android native STT utilities */
  Future<void> _resultListener(SpeechRecognitionResult result) async {
    log('Result listener final: ${result.finalResult}, '
        'words: ${result.recognizedWords}');

    final recorded = result.recognizedWords.trim();
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

  void _soundLevelListener(double level) {
    log('audio level change: $level dB');
  }
  /* END Android native STT utilities */

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
                    final ttsState =
                        context.select((TtsCubit cubit) => cubit.state);
                    if (await ttsState.setLanguage(p13n.locale)) {
                      await ttsState.speak(
                        p13n.content,
                        preferencesState?.volume ??
                            PreferencesState.volumeDefault,
                      );
                    }

                    personalizationCubit
                        ?.setState(PersonalizationCubit.browsingStateLabel);
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
          AnimateStyles.rotateIn(
            _animationController,
            const Icon(Icons.mic_rounded, size: 220),
          ),
          // 3: Processing
          AnimateStyles.rotateIn(
            _animationController,
            const Icon(Icons.text_fields, size: 220),
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () async {
          personalizationCubit
              ?.setState(PersonalizationCubit.recordingStateLabel);

          final options = SpeechListenOptions(
            listenMode: ListenMode.dictation,
            cancelOnError: true,
            partialResults: false,
            autoPunctuation: true,
            enableHapticFeedback: true,
          );

          final sttState = context.select((SttCubit cubit) => cubit.state);
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
        },
      ),
    );
  }
}
