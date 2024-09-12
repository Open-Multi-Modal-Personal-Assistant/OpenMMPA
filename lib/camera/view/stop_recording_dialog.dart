import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:inspector_gadget/l10n/l10n.dart';

Future<OkCancelResult> stopRecordingDialog(BuildContext context) async {
  final l10n = context.l10n;
  return showOkCancelAlertDialog(
    context: context,
    message: l10n.recordingText,
    okLabel: l10n.stopLabel,
    cancelLabel: l10n.cancelLabel,
    defaultType: OkCancelAlertDefaultType.cancel,
    barrierDismissible: false,
  );
}
