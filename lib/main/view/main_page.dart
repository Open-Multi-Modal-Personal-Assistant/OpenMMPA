import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:inspector_gadget/gen/assets.gen.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:inspector_gadget/stt/cubit/stt_cubit.dart';
import 'package:inspector_gadget/utterance/utterance.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SttCubit()),
        BlocProvider(create: (_) => UtteranceCubit()),
      ],
      child: const MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();

  static const String martyMcFlyKey = 'MartyMcFly';
  static const String theDocKey = 'TheDoc';
  static const String translateKey = 'Translate';
  static const String fluxCapacitorKey = 'FluxCapacitor';
}

class _MainViewState extends State<MainView> {
  void navigateWithMode(
    BuildContext context,
    MainCubit mainCubit,
    UtteranceCubit utteranceCubit,
    int utteranceMode,
  ) {
    mainCubit.setState(MainCubit.recordingStateLabel);
    utteranceCubit.setState(utteranceMode);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => UtterancePage(utteranceMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appState = context.select((MainCubit cubit) => cubit.state);
    final mainCubit = context.select((MainCubit cubit) => cubit);
    final utteranceCubit = context.select((UtteranceCubit cubit) => cubit);
    final sttState = context.select((SttCubit cubit) => cubit.state);
    if (!sttState.initialized) {
      sttState.init();
    }

    if (appState.name == 'dummy') {
      mainCubit.setState(MainCubit.waitingStateLabel);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mainAppBarTitle)),
      body: Center(
        child: LayoutGrid(
          columnSizes: [1.fr, 1.fr],
          rowSizes: [1.fr, 1.fr],
          children: [
            IconButton(
              key: const Key(MainView.martyMcFlyKey),
              icon: Assets.martyMcfly.image(),
              iconSize: 150,
              onPressed: () => appState.name == MainCubit.waitingStateLabel
                  ? navigateWithMode(
                      context,
                      mainCubit,
                      utteranceCubit,
                      UtteranceCubit.quickMode,
                    )
                  : null,
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 0,
            ),
            IconButton(
              key: const Key(MainView.theDocKey),
              icon: Assets.doc.image(),
              iconSize: 150,
              onPressed: () => appState.name == MainCubit.waitingStateLabel
                  ? navigateWithMode(
                      context,
                      mainCubit,
                      utteranceCubit,
                      UtteranceCubit.thoroughMode,
                    )
                  : null,
            ).withGridPlacement(
              columnStart: 1,
              rowStart: 0,
            ),
            IconButton(
              key: const Key(MainView.translateKey),
              icon: const Icon(Icons.translate),
              iconSize: 110,
              onPressed: () => appState.name == MainCubit.waitingStateLabel
                  ? navigateWithMode(
                      context,
                      mainCubit,
                      utteranceCubit,
                      UtteranceCubit.translateMode,
                    )
                  : null,
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 1,
            ),
            IconButton(
              key: const Key(MainView.fluxCapacitorKey),
              icon: Assets.fluxCapacitor.image(),
              iconSize: 150,
              onPressed: () => appState.name == MainCubit.waitingStateLabel
                  ? Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const PreferencesPage(),
                      ),
                    )
                  : null,
            ).withGridPlacement(
              columnStart: 1,
              rowStart: 1,
            ),
          ],
        ),
      ),
    );
  }
}
