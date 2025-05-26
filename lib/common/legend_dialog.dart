import 'package:flutter/material.dart';
import 'package:inspector_gadget/l10n/l10n.dart';
import 'package:tuple/tuple.dart';

Future<void> legendDialog(
  BuildContext context,
  List<Tuple2<IconData, String>> legendItems,
) async {
  await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.legendDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: legendItems
              .map(
                (i) => ListTile(
                  leading: Icon(i.item1),
                  title: Text(
                    i.item2,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    ),
  );
}
