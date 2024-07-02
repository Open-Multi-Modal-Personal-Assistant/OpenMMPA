import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/utterance/tools/function_tool.dart';

class LocalTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return true;
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    return Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'fetchGpsLocation',
          'Returns the GPS location of the user.',
          Schema(SchemaType.string),
        ),
        FunctionDeclaration(
          'fetchHeartRate',
          'Returns the heart rate of the user.',
          Schema(SchemaType.integer),
        ),
      ],
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
    PreferencesState? preferences,
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
        location.latitude > 10e-6 &&
        location.longitude > 10e-6) {
      return 'latitude: ${location.latitude}, longitude: ${location.longitude}';
    }

    return 'N/A';
  }

  int _fetchHeartRate(int heartRateParam) {
    return heartRateParam;
  }
}
