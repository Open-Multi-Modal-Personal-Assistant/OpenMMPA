import 'package:daylight/daylight.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/utterance/tools/function_tool.dart';
import 'package:inspector_gadget/utterance/tools/sun_request.dart';

class SunTimeTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return true;
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    return Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'fetchSunrise',
          'Returns the sunrise time for a given GPS location and date.',
          Schema(
            SchemaType.string,
            properties: {
              'latitude': Schema.number(
                description: 'Latitude of the sunrise observer',
              ),
              'longitude': Schema.number(
                description: 'Longitude of the sunrise observer',
              ),
              'date': Schema.string(
                description: 'Date of the sunrise observation',
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'fetchSunset',
          'Returns the sunset time for a given GPS location and date.',
          Schema(
            SchemaType.string,
            properties: {
              'latitude': Schema.number(
                description: 'Latitude of the sunset observer',
              ),
              'longitude': Schema.number(
                description: 'Longitude of the sunset observer',
              ),
              'date': Schema.string(
                description: 'Date of the sunset observation',
              ),
            },
          ),
        ),
      ],
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return ['fetchSunrise', 'fetchSunset'].contains(call.name);
  }

  @override
  Future<FunctionResponse?> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final result = switch (call.name) {
      'fetchSunrise' => {
          'sunrise': _fetchSunrise(SunRequest.fromJson(call.args)),
        },
      'fetchSunset' => {
          'sunset': _fetchSunset(SunRequest.fromJson(call.args)),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  String _fetchSunTime(SunRequest sunRequest, bool sunrise) {
    final location =
        DaylightLocation(sunRequest.latitude, sunRequest.longitude);
    final daylightCalculator = DaylightCalculator(location);
    final dailyResults = daylightCalculator.calculateForDay(
      sunRequest.date,
      Zenith.astronomical,
    );
    final sunTime = sunrise ? dailyResults.sunrise : dailyResults.sunset;
    return sunTime?.toIso8601String() ?? 'N/A';
  }

  String _fetchSunrise(SunRequest sunRequest) {
    return _fetchSunTime(sunRequest, true);
  }

  String _fetchSunset(SunRequest sunRequest) {
    return _fetchSunTime(sunRequest, false);
  }
}
