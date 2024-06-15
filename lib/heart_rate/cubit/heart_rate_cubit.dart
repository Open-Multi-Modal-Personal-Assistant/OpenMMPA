import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:heart_rate_flutter/heart_rate_flutter.dart';

class HeartRateCubit extends Cubit<int> {
  HeartRateCubit() : super(0) {
    _heartRateStream = HeartRateFlutter().heartBeatStream;
  }

  late Stream<double> _heartRateStream;
  late StreamSubscription<int>? _heartRateSubscription;

  void obtain() => emit(state);

  Future<void> listenToHeartRate() async {
    await _heartRateSubscription!.cancel();

    _heartRateSubscription = _heartRateStream.map<int>((fp) {
      return fp.toInt();
    }).listen(emit);
  }

  @override
  Future<void> close() async {
    await _heartRateSubscription!.cancel();
    return super.close();
  }
}
