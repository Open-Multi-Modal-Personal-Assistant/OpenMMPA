import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:inspector_gadget/counter/counter.dart';
import 'package:inspector_gadget/l10n/l10n.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: const CounterView(),
    );
  }
}

class CounterView extends StatelessWidget {
  const CounterView({super.key});

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
              icon: Image.asset('assets/marty.png'),
              iconSize: 150,
              onPressed: () => debugPrint('Marty button tapped'),
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 0,
            ),
            IconButton(
              icon: Image.asset('assets/doc.png'),
              iconSize: 150,
              onPressed: () => debugPrint('Doc button tapped'),
            ).withGridPlacement(
              columnStart: 1,
              rowStart: 0,
            ),
            IconButton(
              icon: const Icon(Icons.help),
              iconSize: 150,
              onPressed: () => debugPrint('Help button tapped'),
            ).withGridPlacement(
              columnStart: 0,
              rowStart: 1,
            ),
            IconButton(
              icon: Image.asset('assets/flux_capacitor.png'),
              iconSize: 150,
              onPressed: () => debugPrint('Flux button tapped'),
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
