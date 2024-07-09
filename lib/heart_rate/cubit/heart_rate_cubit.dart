import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:heart_rate_flutter/heart_rate_flutter.dart';

class HeartRateCubit extends Cubit<int> {
  HeartRateCubit() : super(0) {
    final heartBeatFlutter = HeartRateFlutter();
    heartBeatFlutter
        .getPlatformVersion()
        .then((platformVersion) => debugPrint('HR $platformVersion'));
    _heartRateStream = heartBeatFlutter.heartBeatStream;
  }

  late Stream<double> _heartRateStream;
  StreamSubscription<int>? _heartRateSubscription;

  void obtain() => emit(state);

  Future<void> listenToHeartRate() async {
    await _heartRateSubscription?.cancel();

    _heartRateSubscription = _heartRateStream.map<int>((fp) {
      return fp.toInt();
    }).listen(emit);
  }

  @override
  Future<void> close() async {
    await _heartRateSubscription?.cancel();
    return super.close();
  }
}
