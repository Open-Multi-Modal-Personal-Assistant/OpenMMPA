import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/ai/service/ai_service.dart';
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/deferred_action.dart';
import 'package:inspector_gadget/common/ok_cancel_alert_dialog.dart';
import 'package:inspector_gadget/database/models/personalization.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/database/service/personalization_state.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:inspector_gadget/speech/view/stt_mixin.dart';
import 'package:inspector_gadget/speech/view/tts_mixin.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';
import 'package:watch_it/watch_it.dart';

class PersonalizationPage extends WatchingStatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => PersonalizationPageState();
}

class PersonalizationPageState extends State<PersonalizationPage>
    with
        SingleTickerProviderStateMixin,
        SttMixin,
        TtsMixin,
        WidgetsBindingObserver {
  late AnimationController _animationController;
  int _editCount = 0;
  late DatabaseService database;
  late PreferencesService preferences;
  String inputLocaleId = PreferencesService.inputLocaleDefault;
  bool areSpeechServicesNative =
      PreferencesService.areSpeechServicesNativeDefault;
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

    GetIt.I.get<PersonalizationState>().setState(StateBase.browsingStateLabel);
    database = GetIt.I.get<DatabaseService>();
    preferences = GetIt.I.get<PreferencesService>();

    WidgetsBinding.instance.addObserver(this);

    deferredActionQueue.add(DeferredAction(ActionKind.initialize));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    disposeStt();
    disposeTts();
    super.dispose();
  }

  Future<void> embedAndPersistPersonalization(
    String recorded,
    String localeId,
  ) async {
    final personalizationViewState = GetIt.I.get<PersonalizationState>();
    if (recorded.isNotEmpty) {
      personalizationViewState.setState(StateBase.llmStateLabel);
      final aiService = GetIt.I.get<AiService>();
      final embedding = await aiService.obtainEmbedding(recorded);
      final personalization = Personalization(recorded, localeId)
        ..embedding = embedding;
      database.addUpdatePersonalization(personalization);

      setState(() {
        _editCount++;
      });
    }

    personalizationViewState.setState(StateBase.browsingStateLabel);
  }

  void addToDeferredQueue(DeferredAction deferredAction) {
    deferredActionQueue.add(deferredAction);
    setState(() {});
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
            final ttsService = GetIt.I.get<TtsService>();
            if (ttsService.languages.isEmpty &&
                sttService.localeNames.isNotEmpty) {
              ttsService.supplementLanguages(sttService.localeNames);
            }
          case ActionKind.speechTranscripted:
            await embedAndPersistPersonalization(
              deferredAction.text,
              deferredAction.locale,
            );
            setState(() {});
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
                    await tts(
                      context,
                      p13n.content,
                      p13n.locale,
                      personalizationViewState,
                      StateBase.browsingStateLabel,
                      preferences,
                      areSpeechServicesNative: areSpeechServicesNative,
                    );
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
                    if (await okCancelAlertDialog(context) ==
                        OkCancelResult.ok) {
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
              const Icon(Icons.mic, size: 220),
            ),
            onTap: () async {
              await stopSpeechRecording(
                context,
                personalizationViewState,
                areSpeechServicesNative: areSpeechServicesNative,
              );
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
              personalizationViewState.setState(StateBase.browsingStateLabel);
            },
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () async {
          personalizationViewState.setState(StateBase.recordingStateLabel);
          inputLocaleId = preferences.inputLocale;

          await stt(
            context,
            inputLocaleId,
            personalizationViewState,
            StateBase.browsingStateLabel,
            preferences,
            addToDeferredQueue,
            areSpeechServicesNative: areSpeechServicesNative,
          );
        },
      ),
    );
  }
}
