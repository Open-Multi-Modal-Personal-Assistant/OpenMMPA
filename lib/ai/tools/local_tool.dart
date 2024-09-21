import 'dart:convert';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:fl_location/fl_location.dart';
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

class LocalTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesService preferences) {
    return true;
  }

  @override
  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesService preferences,
  ) {
    return [
      FunctionDeclaration(
        'fetchGpsLocation',
        "Returns the current GPS location's latitude and longitude.",
        Schema(SchemaType.string),
      ),
      // FunctionDeclaration(
      //   'fetchHeartRate',
      //   'Returns the current heart rate measurement.',
      //   Schema(SchemaType.integer),
      // ),
    ];
  }

  @override
  Tool getTool(PreferencesService preferences) {
    return Tool(
      functionDeclarations: getFunctionDeclarations(preferences),
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return ['fetchGpsLocation', 'fetchHeartRate'].contains(call.name);
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesService preferences,
  ) async {
    final result = switch (call.name) {
      'fetchGpsLocation' => {
          'gpsLocation': _fetchGpsLocation(location),
        },
      'fetchHeartRate' => {
          'heartRate': _fetchHeartRate(hr),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  String _fetchGpsLocation(Location? location) {
    if (location != null &&
        (location.latitude.abs() > 10e-6 || location.longitude.abs() > 10e-6)) {
      return json.encode({
        'latitude': location.latitude,
        'longitude': location.longitude,
      });
    }

    return 'N/A';
  }

  int _fetchHeartRate(int heartRateParam) {
    return heartRateParam;
  }
}
