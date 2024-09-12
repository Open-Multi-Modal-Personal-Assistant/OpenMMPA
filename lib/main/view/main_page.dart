import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:inspector_gadget/camera/view/camera_page.dart';
import 'package:inspector_gadget/common/legend_dialog.dart';
import 'package:inspector_gadget/database/view/personalization_page.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/preferences/view/preferences_page.dart';
import 'package:tuple/tuple.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const String uniModalKey = 'UniModal';
  static const String multiModalKey = 'MultiModal';
  static const String translateKey = 'Translate';
  static const String personalizationKey = 'Personalization';
  static const String settingsKey = 'Settings';
  static const String helpKey = 'Help';

  void navigateWithMode(BuildContext context, InteractionMode interactionMode) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            InteractionPage(interactionMode, mediaFiles: const []),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.of(context).size;
    final horizontal = size.width >= size.height;
    final columnSizes = [1.fr, 1.fr];
    final rowSizes = [1.fr, 1.fr];
    var iconSize = 1.0;
    // https://www.geeksforgeeks.org/flutter-set-the-height-of-the-appbar/
    const appBarHeight = 56;
    if (horizontal) {
      columnSizes.add(1.fr);
      iconSize = min(size.width / 3.5, (size.height - appBarHeight) / 2.5);
    } else {
      rowSizes.add(1.fr);
      iconSize = min(size.width / 2.5, (size.height - appBarHeight) / 3.5);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mainAppBarTitle)),
      body: Center(
        child: LayoutGrid(
          columnSizes: columnSizes,
          rowSizes: rowSizes,
          children: [
            Center(
              child: IconButton.filledTonal(
                key: const Key(uniModalKey),
                icon: Icon(Icons.chat, size: iconSize),
                onPressed: () => navigateWithMode(
                  context,
                  InteractionMode.textChat,
                ),
              ),
            ),
            Center(
              child: IconButton.filledTonal(
                key: const Key(multiModalKey),
                icon: Icon(Icons.video_chat, size: iconSize),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const CameraPage(),
                  ),
                ),
              ),
            ),
            Center(
              child: IconButton.filledTonal(
                key: const Key(translateKey),
                icon: Icon(Icons.translate, size: iconSize),
                onPressed: () => navigateWithMode(
                  context,
                  InteractionMode.translate,
                ),
              ),
            ),
            Center(
              child: IconButton.filledTonal(
                key: const Key(personalizationKey),
                icon: Icon(Icons.person_add, size: iconSize),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const PersonalizationPage(),
                  ),
                ),
              ),
            ),
            Center(
              child: IconButton.filledTonal(
                key: const Key(settingsKey),
                icon: Icon(Icons.settings, size: iconSize),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const PreferencesPage(),
                  ),
                ),
              ),
            ),
            Center(
              child: IconButton.filledTonal(
                key: const Key(helpKey),
                icon: Icon(Icons.help, size: iconSize),
                onPressed: () async => legendDialog(context, [
                  Tuple2<IconData, String>(
                    Icons.chat,
                    l10n.uniModalButtonDescription,
                  ),
                  Tuple2<IconData, String>(
                    Icons.video_chat,
                    l10n.multiModalButtonDescription,
                  ),
                  Tuple2<IconData, String>(
                    Icons.translate,
                    l10n.translateButtonDescription,
                  ),
                  Tuple2<IconData, String>(
                    Icons.person_add,
                    l10n.personalizationButtonDescription,
                  ),
                  Tuple2<IconData, String>(
                    Icons.settings,
                    l10n.preferencesButtonDescription,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
