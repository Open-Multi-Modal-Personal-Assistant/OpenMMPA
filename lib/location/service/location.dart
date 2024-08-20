import 'dart:async';
import 'dart:developer';

import 'package:fl_location/fl_location.dart';
import 'package:flutter/foundation.dart';

class LocationService with ChangeNotifier {
  LocationService() {
    final now = DateTime.now();
    mockLocation = Location(
      latitude: 36.7420,
      longitude: -119.7702,
      accuracy: 0,
      altitude: 94,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      millisecondsSinceEpoch: now.millisecondsSinceEpoch.toDouble(),
      timestamp: now,
      isMock: true,
    );
    location = mockLocation;
  }

  late Location mockLocation;
  late Location location;

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

  Future<Location> obtain() async {
    if (!(await _checkAndRequestPermission())) {
      return mockLocation;
    }

    try {
      final location = await FlLocation.getLocation(
        accuracy: LocationAccuracy.navigation,
        timeLimit: const Duration(milliseconds: 500),
      );
      return location;
    } catch (e) {
      log('Exception while obtaining location: $e');
      return mockLocation;
    }
  }
}
