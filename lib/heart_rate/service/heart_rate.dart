import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:heart_rate_flutter/heart_rate_flutter.dart';

class HeartRateService with ChangeNotifier {
  HeartRateService() {
    final heartBeatFlutter = HeartRateFlutter();
    heartBeatFlutter
        .getPlatformVersion()
        .then((platformVersion) => debugPrint('HR $platformVersion'));
    _heartRateStream = heartBeatFlutter.heartBeatStream;
  }

  int heartRate = 0;

  late Stream<double> _heartRateStream;
  StreamSubscription<double>? _heartRateSubscription;

  void listenToHeartRate() {
    if (_heartRateSubscription != null) {
      return;
    }

    _heartRateSubscription = _heartRateStream.listen((hr) {
      if (hr > 0) {
        heartRate = hr.toInt();
      }
    });
  }

  Future<void> cancel() async {
    await _heartRateSubscription?.cancel();
  }
}