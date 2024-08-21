import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/database/service/history_state.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:inspector_gadget/speech/service/tts.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';
import 'package:watch_it/watch_it.dart';

class HistoryPage extends StatefulWidget with WatchItStatefulWidgetMixin {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  int _editCount = 0;
  late DatabaseService database;
  late PreferencesService preferences;

  @override
  void didChangeMetrics() {
    setState(() {
      _editCount++;
    });
  }

  @override
  void initState() {
    super.initState();

    GetIt.I.get<HistoryState>().setState(HistoryState.browsingStateLabel);
    database = GetIt.I.get<DatabaseService>();
    preferences = GetIt.I.get<PreferencesService>();

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stateIndex = watchPropertyValue((HistoryState s) => s.stateIndex);

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
                    final historyViewState = GetIt.I.get<HistoryState>()
                      ..setState(HistoryState.playingStateLabel);
                    final ttsService = GetIt.I.get<TtsService>();
                    await ttsService.speak(history.content, preferences.volume);
                    historyViewState.setState(HistoryState.browsingStateLabel);
                  },
                  icon: const Icon(Icons.play_arrow),
                ),
              );
            },
          ),
          // 1: Playback phase
          AnimateStyles.pulse(
            _animationController,
            const Icon(Icons.speaker, size: 220),
          ),
        ],
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final result = await showOkCancelAlertDialog(
            context: context,
            message: l10n.areYouSureText,
            okLabel: l10n.okLabel,
            cancelLabel: l10n.cancelLabel,
            defaultType: OkCancelAlertDefaultType.cancel,
          );

          if (result == OkCancelResult.ok) {
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
