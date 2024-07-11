import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/interaction/tools/function_tool.dart';
import 'package:inspector_gadget/interaction/tools/geo_request.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class WeatherTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return true;
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    return Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'fetchWeatherForecast',
          'Fetch the current weather measurements (such as temperature (C), '
              'wind speed and direction, humidity, precipitation) and also '
              'weather forecast of the near future for a given GPS coordinate, '
              'all in JSON format',
          Schema(
            SchemaType.object,
            properties: {
              'latitude': Schema.number(
                description: 'Latitude of the weather observation and forecast',
              ),
              'longitude': Schema.number(
                description:
                    'Longitude of the weather observation and forecast',
              ),
            },
            requiredProperties: ['latitude', 'longitude'],
          ),
        ),
      ],
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return call.name == 'fetchWeatherForecast';
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final result = switch (call.name) {
      'fetchWeatherForecast' => {
          'query': await _fetchWeatherForecast(GeoRequest.fromJson(call.args)),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  Future<String> _fetchWeatherForecast(GeoRequest geoRequest) async {
    if (geoRequest.latitude.abs() < 10e-6 &&
        geoRequest.longitude.abs() < 10e-6) {
      return 'N/A';
    }

    const weatherApiBaseUrl = 'www.7timer.info';
    const weatherApiPath = '/bin/api.pl';
    final weatherApiUrl = Uri.http(weatherApiBaseUrl, weatherApiPath, {
      'lon': geoRequest.longitude,
      'lat': geoRequest.latitude,
      'product': 'civil', // meteo is more detailed but way longer
      'output': 'json',
    });

    final forecastResult = await http.get(weatherApiUrl);
    if (forecastResult.statusCode == 200) {
      return forecastResult.body;
    }

    return 'N/A';
  }
}
