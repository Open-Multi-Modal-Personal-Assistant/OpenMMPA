import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:inspector_gadget/heart_rate/heart_rate.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:inspector_gadget/location/location.dart';
import 'package:inspector_gadget/main/main.dart';
import 'package:inspector_gadget/preferences/preferences.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MainCubit()),
        BlocProvider(create: (_) => LocationCubit()),
        BlocProvider(create: (_) => HeartRateCubit()),
      ],
      child: const MainView(),
    );
  }
}

class MainView extends StatelessWidget {
  const MainView({super.key});

  static const String martyMcFlyKey = 'MartyMcFly';
  static const String theDocKey = 'TheDoc';
  static const String translateKey = 'Translate';
  static const String fluxCapacitorKey = 'FluxCapacitor';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mainAppBarTitle)),
      body: Center(
        child: LayoutGrid(
          columnSizes: [1.fr, 1.fr],
          rowSizes: [1.fr, 1.fr],
          children: [
            IconButton(
              key: const Key(martyMcFlyKey),
              icon: Image.asset('assets/marty_mcfly.png'),
              iconSize: 150,
              onPressed: () => debugPrint('Marty button tapped'),
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 0,
            ),
            IconButton(
              key: const Key(theDocKey),
              icon: Image.asset('assets/doc.png'),
              iconSize: 150,
              onPressed: () => debugPrint('Doc button tapped'),
            ).withGridPlacement(
              columnStart: 1,
              rowStart: 0,
            ),
            IconButton(
              key: const Key(translateKey),
              icon: const Icon(Icons.translate),
              iconSize: 110,
              onPressed: () => debugPrint('Translate button tapped'),
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 1,
            ),
            IconButton(
              key: const Key(fluxCapacitorKey),
              icon: Image.asset('assets/flux_capacitor.png'),
              iconSize: 150,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const PreferencesPage(),
                ),
              ),
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
