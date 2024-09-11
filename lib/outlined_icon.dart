import 'package:flutter/material.dart';

Widget outlinedIcon(
  BuildContext context,
  IconData iconData,
  double iconSize, {
  Color? color,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Stack(
    children: [
      Center(
        child: Icon(iconData, size: iconSize * 1.1, color: colorScheme.shadow),
      ),
      Center(
        child: Icon(
          iconData,
          size: iconSize,
          color: color ?? colorScheme.primary,
        ),
      ),
    ],
  );
}
