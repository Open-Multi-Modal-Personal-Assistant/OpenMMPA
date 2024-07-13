import 'package:daylight/daylight.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/interaction/tools/function_tool.dart';
import 'package:inspector_gadget/interaction/tools/geo_request.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class SunTimeTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return true;
  }

  @override
  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesState? preferences,
  ) {
    return [
      FunctionDeclaration(
        'fetchSunrise',
        'Returns the sunrise time for a given GPS location and date.',
        Schema(
          SchemaType.object,
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
          requiredProperties: ['latitude', 'longitude'],
        ),
      ),
      FunctionDeclaration(
        'fetchSunset',
        'Returns the sunset time for a given GPS location and date.',
        Schema(
          SchemaType.object,
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
          requiredProperties: ['latitude', 'longitude'],
        ),
      ),
    ];
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    return Tool(
      functionDeclarations: getFunctionDeclarations(preferences),
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
          'sunrise': _fetchSunrise(GeoRequest.fromJson(call.args)),
        },
      'fetchSunset' => {
          'sunset': _fetchSunset(GeoRequest.fromJson(call.args)),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  String _fetchSunTime(GeoRequest geoRequest, bool sunrise) {
    if (geoRequest.latitude.abs() < 10e-6 &&
        geoRequest.longitude.abs() < 10e-6) {
      return 'N/A';
    }

    final location =
        DaylightLocation(geoRequest.latitude, geoRequest.longitude);
    final daylightCalculator = DaylightCalculator(location);
    final dailyResults = daylightCalculator.calculateForDay(
      geoRequest.date,
      Zenith.astronomical,
    );
    final sunTime = sunrise ? dailyResults.sunrise : dailyResults.sunset;
    return sunTime?.toIso8601String() ?? 'N/A';
  }

  String _fetchSunrise(GeoRequest geoRequest) {
    return _fetchSunTime(geoRequest, true);
  }

  String _fetchSunset(GeoRequest geoRequest) {
    return _fetchSunTime(geoRequest, false);
  }
}
