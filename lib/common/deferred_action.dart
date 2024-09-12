enum ActionKind {
  initialize,
  speechTranscripted,
}

class DeferredAction {
  DeferredAction(
    this.actionKind, {
    this.text = '',
    this.locale = '',
    this.integer = 0,
    this.floatingPoint = 0,
  });

  ActionKind actionKind;
  String text = '';
  String locale = '';
  int integer = 0;
  double floatingPoint = 0;
}
