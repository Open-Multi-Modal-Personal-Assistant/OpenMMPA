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
  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesState? preferences,
  ) {
    return [
      FunctionDeclaration(
        'fetchWeatherForecast',
        'Returns the weather in a given location.',
        Schema(
          SchemaType.object,
          properties: {
            'latitude': Schema.number(
              description: 'Latitude of the weather observation and forecast',
            ),
            'longitude': Schema.number(
              description: 'Longitude of the weather observation and forecast',
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
    return call.name == 'fetchWeatherForecast';
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final isMetric =
        preferences?.unitSystem ?? PreferencesState.getUnitSystemDefault();
    final result = switch (call.name) {
      'fetchWeatherForecast' => {
          'query': await _fetchWeatherForecast(
            GeoRequest.fromJson(call.args),
            isMetric,
          ),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  Future<String> _fetchWeatherForecast(
    GeoRequest geoRequest,
    bool isMetric,
  ) async {
    if (geoRequest.latitude.abs() < 10e-6 &&
        geoRequest.longitude.abs() < 10e-6) {
      return 'N/A';
    }

    // By Doc: https://www.7timer.info/bin/api.pl?lon=-119.8&lat=36.9&product=civil&output=json
    // Result: https://www.7timer.info/bin/civil.php?lon=-119.8&lat=36.9&ac=0&unit=metric&output=json&tzshift=0
    // Minimal: https://www.7timer.info/bin/civil.php?lon=-119.8&lat=36.9&output=json
    const weatherApiBaseUrl = 'www.7timer.info';
    const weatherApiPath = '/bin/api.pl';
    final weatherApiUrl = Uri.http(weatherApiBaseUrl, weatherApiPath, {
      'lon': geoRequest.longitude.toString(),
      'lat': geoRequest.latitude.toString(),
      'product': 'civil', // meteo is more detailed but way longer
      'unit': isMetric ? 'metric' : 'british',
      'output': 'json',
    });

    final forecastResult = await http.get(weatherApiUrl);
    if (forecastResult.statusCode == 200) {
      return forecastResult.body;
    }

    return 'N/A';
  }
}
