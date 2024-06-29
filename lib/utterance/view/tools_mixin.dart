import 'package:daylight/daylight.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/utterance/view/sun_request.dart';

mixin ToolsMixin {
  List<Tool> getTools() {
    return [
      Tool(
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
      ),
    ];
  }

  FunctionResponse dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
  ) {
    final result = switch (call.name) {
      'fetchGpsLocation' => {
          'gpsLocation': _fetchGpsLocation(location),
        },
      'fetchHeartRate' => {
          'heartRate': _fetchHeartRate(hr),
        },
      'fetchSunrise' => {
          'sunrise': _fetchSunrise(SunRequest.fromJson(call.args)),
        },
      'fetchSunset' => {
          'sunset': _fetchSunset(SunRequest.fromJson(call.args)),
        },
      _ => throw UnimplementedError('Function not implemented: ${call.name}')
    };
    return FunctionResponse(call.name, result);
  }

  String _fetchGpsLocation(Location? location) {
    if (location != null &&
        location.latitude > 10e-6 &&
        location.longitude > 10e-6) {
      return 'latitude ${location.latitude} longitude ${location.longitude}';
    }

    return 'N/A';
  }

  int _fetchHeartRate(int heartRateParam) {
    return heartRateParam;
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
