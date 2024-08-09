import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_animations/flutter_easy_animations.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/database/cubit/history_cubit.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:inspector_gadget/tts/cubit/tts_cubit.dart';
import 'package:listview_utils_plus/listview_utils_plus.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<DatabaseCubit>(),
      child: BlocProvider.value(
        value: context.read<TtsCubit>(),
        child: BlocProvider.value(
          value: context.read<PreferencesCubit>(),
          child: BlocProvider(
            create: (_) => HistoryCubit(),
            child: const HistoryView(),
          ),
        ),
      ),
    );
  }
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  int _editCount = 0;
  PreferencesState? preferencesState;
  DatabaseCubit? database;
  HistoryCubit? historyCubit;

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    preferencesState = context.select((PreferencesCubit cubit) => cubit.state);
    database = context.select((DatabaseCubit cubit) => cubit);
    historyCubit =
        context.select((HistoryCubit cubit) => cubit);
    final stateIndex =
    context.select((HistoryCubit cubit) => cubit.getStateIndex());

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
                final data =
                await database?.historyPaged(page * limit, limit);
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
                    historyCubit
                        ?.setState(HistoryCubit.playingStateLabel);
                    final ttsState =
                    context.select((TtsCubit cubit) => cubit.state);
                    await ttsState.speak(
                      history.content,
                      preferencesState?.volume ??
                          PreferencesState.volumeDefault,
                    );
                    historyCubit
                        ?.setState(HistoryCubit.browsingStateLabel);
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
    );
  }
}
