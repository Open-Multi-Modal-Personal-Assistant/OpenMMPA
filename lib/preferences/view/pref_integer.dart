import 'package:flutter/material.dart';
import 'package:number_selector/number_selector.dart';
import 'package:pref/pref.dart';

class PrefInteger extends StatefulWidget {
  const PrefInteger({
    required this.pref,
    required this.min,
    required this.max,
    super.key,
    this.title,
    this.subtitle,
    this.onChange,
    this.disabled,
  });

  final Widget? title;
  final Widget? subtitle;
  final String pref;
  final bool? disabled;
  final ValueChanged<int?>? onChange;
  final int min;
  final int max;

  @override
  PrefIntegerState createState() => PrefIntegerState();
}

class PrefIntegerState extends State<PrefInteger> {
  Color borderColor = Colors.black26;
  Color backgroundColor = Colors.white;
  Color iconColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return PrefCustom<int>.widget(
      pref: widget.pref,
      title: widget.title,
      subtitle: widget.subtitle,
      onChange: widget.onChange,
      disabled: widget.disabled,
      builder: (context, value, onChange) => NumberSelector(
        current: value ?? 0,
        min: widget.min,
        max: widget.max,
        contentPadding: 1,
        verticalDividerPadding: 1,
        showSuffix: false,
        showMinMax: false,
        borderColor: borderColor,
        dividerColor: borderColor,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        onUpdate: onChange,
      ),
    );
  }
}
