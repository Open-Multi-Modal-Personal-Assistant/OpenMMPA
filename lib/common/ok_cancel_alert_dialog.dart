import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:inspector_gadget/l10n/l10n.dart';

Future<OkCancelResult> okCancelAlertDialog(BuildContext context) async {
  final l10n = context.l10n;
  return showOkCancelAlertDialog(
    context: context,
    message: l10n.areYouSureText,
    okLabel: l10n.okLabel,
    cancelLabel: l10n.cancelLabel,
    defaultType: OkCancelAlertDefaultType.cancel,
    isDestructiveAction: true,
  );
}
