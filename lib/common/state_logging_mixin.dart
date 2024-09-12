import 'dart:developer';

import 'package:flutter/foundation.dart';

mixin StateLoggingMixin {
  final bool _logEvents = kDebugMode;

  void logEvent(String eventDescription) {
    final eventTime = DateTime.now().toIso8601String();
    final logString = '$eventTime $eventDescription';
    debugPrint(logString);
    if (_logEvents) {
      log(logString, time: DateTime.now());
    }
  }
}
