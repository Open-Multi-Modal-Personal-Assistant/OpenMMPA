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
      final location =
          await FlLocation.getLocation(accuracy: LocationAccuracy.navigation);
      emit(location);
      return location;
    } catch (e) {
      log('Exception while obtaining location: $e');
      return null;
    }
  }
}
