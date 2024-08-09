import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:inspector_gadget/interaction/interaction.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/legend_dialog.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/preferences.dart';
import 'package:tuple/tuple.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const String uniModalKey = 'UniModal';
  // static const String translateKey = 'Translate';
  static const String multiModalKey = 'MultiModal';
  static const String settingsKey = 'Settings';
  static const String helpKey = 'Help';

  void navigateWithMode(
    BuildContext context,
    MainCubit mainCubit,
    InteractionMode interactionMode,
  ) {
    mainCubit.setState(MainCubit.recordingStateLabel);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => InteractionPage(interactionMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mainCubit = context.select((MainCubit cubit) => cubit);
    final size = MediaQuery.of(context).size;
    // https://www.geeksforgeeks.org/flutter-set-the-height-of-the-appbar/
    const appBarHeight = 56;
    final iconSize = min(size.width / 2, (size.height - appBarHeight) / 2);

    final clickableState = [
      MainCubit.waitingStateLabel,
      MainCubit.doneStateLabel,
      MainCubit.errorStateLabel,
    ].contains(mainCubit.state.name);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mainAppBarTitle)),
      body: Center(
        child: LayoutGrid(
          columnSizes: [1.fr, 1.fr],
          rowSizes: [1.fr, 1.fr],
          children: [
            IconButton(
              key: const Key(uniModalKey),
              icon: const Icon(Icons.chat),
              iconSize: iconSize,
              onPressed: () => clickableState
                  ? navigateWithMode(
                      context,
                      mainCubit,
                      InteractionMode.uniModalMode,
                    )
                  : null,
            ),
            IconButton(
              key: const Key(multiModalKey),
              icon: const Icon(Icons.video_chat),
              iconSize: iconSize,
              onPressed: () => clickableState
                  ? navigateWithMode(
                      context,
                      mainCubit,
                      InteractionMode.multiModalMode,
                    )
                  : null,
            ),
            IconButton(
              key: const Key(settingsKey),
              icon: const Icon(Icons.settings),
              iconSize: iconSize,
              onPressed: () => clickableState
                  ? Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const PreferencesPage(),
                      ),
                    )
                  : null,
            ),
            IconButton(
              key: const Key(helpKey),
              icon: const Icon(Icons.help),
              iconSize: iconSize,
              onPressed: () async => legendDialog(context, [
                Tuple2<IconData, String>(
                  Icons.chat,
                  l10n.uniModalButtonDescription,
                ),
                Tuple2<IconData, String>(
                  Icons.translate,
                  l10n.translateButtonDescription,
                ),
                Tuple2<IconData, String>(
                  Icons.video_chat,
                  l10n.multiModalButtonDescription,
                ),
                Tuple2<IconData, String>(
                  Icons.dataset,
                  l10n.databaseButtonDescription,
                ),
                Tuple2<IconData, String>(
                  Icons.settings,
                  l10n.preferencesButtonDescription,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
