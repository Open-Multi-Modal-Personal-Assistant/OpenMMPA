import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:fl_location/fl_location.dart';

class LocationCubit extends Cubit<Location?> {
  LocationCubit() : super(null);

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

  Future<Location?> obtain() async {
    if (!(await _checkAndRequestPermission())) {
      return null;
    }

    try {
      // final now = DateTime.now();
      // final location = Location(
      //   latitude: 36.7420,
      //   longitude: -119.7702,
      //   accuracy: 0,
      //   altitude: 94,
      //   heading: 0,
      //   speed: 0,
      //   speedAccuracy: 0,
      //   millisecondsSinceEpoch: now.millisecondsSinceEpoch.toDouble(),
      //   timestamp: now,
      //   isMock: true,
      // );

      final location = await FlLocation.getLocation(
        accuracy: LocationAccuracy.navigation,
        timeLimit: const Duration(milliseconds: 500),
      );
      emit(location);
      return location;
    } catch (e) {
      log('Exception while obtaining location: $e');
      return null;
    }
  }
}
