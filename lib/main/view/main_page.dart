import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:inspector_gadget/gen/assets.gen.dart';
import 'package:inspector_gadget/interaction/utterance.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/preferences.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const String martyMcFlyKey = 'MartyMcFly';
  static const String theDocKey = 'TheDoc';
  static const String translateKey = 'Translate';
  static const String fluxCapacitorKey = 'FluxCapacitor';

  void navigateWithMode(
    BuildContext context,
    MainCubit mainCubit,
    int utteranceMode,
  ) {
    mainCubit.setState(MainCubit.recordingStateLabel);
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
    final mainCubit = context.select((MainCubit cubit) => cubit);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mainAppBarTitle)),
      body: Center(
        child: LayoutGrid(
          columnSizes: [1.fr, 1.fr],
          rowSizes: [1.fr, 1.fr],
          children: [
            IconButton(
              key: const Key(martyMcFlyKey),
              icon: Assets.martyMcfly.image(),
              iconSize: 150,
              onPressed: () =>
                  mainCubit.state.name == MainCubit.waitingStateLabel
                      ? navigateWithMode(
                          context,
                          mainCubit,
                          UtteranceCubit.quickMode,
                        )
                      : null,
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 0,
            ),
            IconButton(
              key: const Key(theDocKey),
              icon: Assets.doc.image(),
              iconSize: 150,
              onPressed: () =>
                  mainCubit.state.name == MainCubit.waitingStateLabel
                      ? navigateWithMode(
                          context,
                          mainCubit,
                          UtteranceCubit.thoroughMode,
                        )
                      : null,
            ).withGridPlacement(
              columnStart: 1,
              rowStart: 0,
            ),
            IconButton(
              key: const Key(translateKey),
              icon: const Icon(Icons.translate),
              iconSize: 110,
              onPressed: () =>
                  mainCubit.state.name == MainCubit.waitingStateLabel
                      ? navigateWithMode(
                          context,
                          mainCubit,
                          UtteranceCubit.translateMode,
                        )
                      : null,
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 1,
            ),
            IconButton(
              key: const Key(fluxCapacitorKey),
              icon: Assets.fluxCapacitor.image(),
              iconSize: 150,
              onPressed: () =>
                  mainCubit.state.name == MainCubit.waitingStateLabel
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
