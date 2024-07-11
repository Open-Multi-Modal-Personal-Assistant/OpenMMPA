enum ActionKind {
  initialize,
  volumeAdjust,
  speechTranscripted,
}

class DeferredAction {
  DeferredAction(
    this.actionKind, {
    this.text = '',
    this.integer = 0,
    this.floatingPoint = 0,
  });

  ActionKind actionKind;
  String text = '';
  int integer = 0;
  double floatingPoint = 0;
}
