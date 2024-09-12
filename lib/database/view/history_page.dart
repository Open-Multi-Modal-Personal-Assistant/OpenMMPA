import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/common/base_state.dart';
import 'package:inspector_gadget/common/deferred_action.dart';
import 'package:inspector_gadget/common/ok_cancel_alert_dialog.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/database/service/history_state.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/stt.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:inspector_gadget/speech/view/tts_mixin.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';
import 'package:watch_it/watch_it.dart';

class HistoryPage extends WatchingStatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin, TtsMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  int _editCount = 0;
  late DatabaseService database;
  late PreferencesService preferences;
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

    GetIt.I.get<HistoryState>().setState(StateBase.browsingStateLabel);
    database = GetIt.I.get<DatabaseService>();
    preferences = GetIt.I.get<PreferencesService>();

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
    _animationController.dispose();
    disposeTts();
    super.dispose();
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
            debugPrint('Invalid ActionKind ${deferredAction.actionKind}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stateIndex = watchPropertyValue((HistoryState s) => s.stateIndex);

    _processDeferredActionQueue(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyAppBarTitle)),
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
                final data = await database.historyPaged(page * limit, limit);
                return ListItems(data, reachedToEnd: data.length < limit);
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
              final history = item as History;
              return ListTile(
                key: Key('h_${history.id}'),
                leading: Icon(history.getIcon()),
                subtitle: Text(
                  history.content,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  onPressed: () async {
                    await tts(
                      context,
                      history.content,
                      history.locale,
                      GetIt.I.get<HistoryState>(),
                      StateBase.browsingStateLabel,
                      preferences,
                      areSpeechServicesNative: areSpeechServicesNative,
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                ),
              );
            },
          ),
          // 1: TTS phase
          AnimateStyles.pulse(
            _animationController,
            const Icon(Icons.transcribe, size: 220),
          ),
          // 2: Playback phase
          AnimateStyles.pulse(
            _animationController,
            const Icon(Icons.speaker, size: 220),
          ),
          // 7: Error phase
          GestureDetector(
            child: AnimateStyles.pulse(
              _animationController,
              const Icon(Icons.warning, size: 220),
            ),
            onTap: () => GetIt.I
                .get<HistoryState>()
                .setState(StateBase.browsingStateLabel),
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          if (await okCancelAlertDialog(context) == OkCancelResult.ok) {
            database.clearHistory();
            setState(() {
              _editCount++;
            });
          }
        },
      ),
    );
  }
}
