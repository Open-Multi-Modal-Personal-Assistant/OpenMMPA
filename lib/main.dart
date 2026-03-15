import 'dart:async';

import 'package:inspector_gadget/app/view/app_view.dart';
import 'package:inspector_gadget/bootstrap.dart';

void main() {
  unawaited(bootstrap(() => const AppView()));
}
