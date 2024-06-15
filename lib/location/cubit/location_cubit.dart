import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fl_location/fl_location.dart';

class LocationCubit extends Cubit<Location> {
  LocationCubit()
      : super(
          Location(
            latitude: 0,
            longitude: 0,
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            millisecondsSinceEpoch:
                DateTime.now().millisecondsSinceEpoch.toDouble(),
            timestamp: DateTime.now(),
            isMock: true,
          ),
        );

  Future<bool> _checkAndRequestPermission() async {
    if (!await FlLocation.isLocationServicesEnabled) {
      // Location services are disabled.
      return false;
    }

    var locationPermission = await FlLocation.checkLocationPermission();
    if (locationPermission == LocationPermission.deniedForever) {
      // Cannot request runtime permission because
      // location permission is denied forever.
      return false;
    } else if (locationPermission == LocationPermission.denied) {
      // Ask the user for location permission.
      locationPermission = await FlLocation.requestLocationPermission();
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) return false;
    }

    // Location services has been enabled and permission have been granted.
    return true;
  }

  Future<void> obtain() async {
    if (await _checkAndRequestPermission()) {
      const timeLimit = Duration(milliseconds: 500);
      await FlLocation.getLocation(timeLimit: timeLimit)
          .then(emit)
          .onError((error, stackTrace) {
        // TODO(MrCsabaToth): log error
      });
    }
  }
}
