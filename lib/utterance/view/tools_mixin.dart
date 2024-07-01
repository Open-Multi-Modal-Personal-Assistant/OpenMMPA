import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:daylight/daylight.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/utterance/view/currency_request.dart';
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
          FunctionDeclaration(
            'fetchCurrencyExchangeRate',
            'Returns exchange rate for currencies between countries.',
            Schema(
              SchemaType.number,
              properties: {
                'currencyDate': Schema.string(
                  description: 'A date or the value "latest" '
                      'if a time period is not specified',
                ),
                'currencyFrom': Schema.string(
                  description:
                      'The currency to convert from in ISO 4217 format',
                ),
                'currencyTo': Schema.string(
                  description: 'The currency to convert to in ISO 4217 format',
                ),
              },
              requiredProperties: ['currencyFrom', 'currencyTo'],
            ),
          ),
        ],
      ),
    ];
  }

  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
  ) async {
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
      'fetchCurrencyExchangeRate' => {
          'exchangeRate': await _fetchCurrencyExchangeRate(
            CurrencyRequest.fromJson(call.args),
          ),
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

  Future<double> _fetchCurrencyExchangeRate(
    CurrencyRequest currencyRequest,
  ) async {
    const frankfurterBaseUrl = 'https://api.frankfurter.app/';
    final formattedDate = currencyRequest.currencyDate.format('yyyy-MM-dd');
    final urlParameters = '$formattedDate'
        '?from=${currencyRequest.currencyFrom}'
        '&to=${currencyRequest.currencyTo}'
        '&amount=${currencyRequest.amountFrom}';
    final exchangeResult =
        await http.get(Uri.parse('$frankfurterBaseUrl$urlParameters'));
    if (exchangeResult.statusCode == 200) {
      final exchangeJson =
          json.decode(exchangeResult.body) as Map<String, dynamic>;
      if (exchangeJson.containsKey('rates')) {
        final rates = exchangeJson['rates'] as Map<String, double>;
        if (rates.containsKey(currencyRequest.currencyTo)) {
          return rates[currencyRequest.currencyTo]!;
        }
      }
    }

    return 0.0;
  }
}
