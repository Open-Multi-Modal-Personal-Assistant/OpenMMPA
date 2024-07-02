import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:daylight/daylight.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/utterance/view/currency_request.dart';
import 'package:inspector_gadget/utterance/view/sun_request.dart';

mixin ToolsMixin {
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co';
  static const String alphaVantagePath = '/query';

  List<Tool> getTools(PreferencesState? preferences) {
    final tools = [
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
        ],
      ),
      Tool(
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
      ),
      Tool(
        functionDeclarations: [
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
                'amountFrom': Schema.number(
                  description: 'The amount which needs to be converted, '
                      'defaults to 1.0',
                ),
              },
              requiredProperties: ['currencyFrom', 'currencyTo'],
            ),
          ),
        ],
      ),
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'webSearch',
            'Search the web and wikipedia for facts about any topic or '
                'gather munition to answer any questions',
            Schema(
              SchemaType.string,
              properties: {
                'query': Schema.string(
                  description: 'The web search query or question need to be '
                      'researched or answered',
                ),
              },
              requiredProperties: ['query'],
            ),
          ),
        ],
      ),
    ];

    if (!(preferences?.alphaVantageAccessKey.isNullOrWhiteSpace ?? false)) {
      tools.add(
        Tool(
          functionDeclarations: [
            FunctionDeclaration(
              'getStockPrice',
              'Fetch the current stock price of a given company in JSON string',
              Schema(
                SchemaType.string,
                properties: {
                  'ticker': Schema.string(
                    description: 'Stock ticker symbol for a company',
                  ),
                },
                requiredProperties: ['ticker'],
              ),
            ),
            FunctionDeclaration(
              'getCompanyOverview',
              'Get company details and other financial data in JSON string',
              Schema(
                SchemaType.string,
                properties: {
                  'ticker': Schema.string(
                    description: 'Stock ticker symbol for a company',
                  ),
                },
                requiredProperties: ['ticker'],
              ),
            ),
            FunctionDeclaration(
              'getCompanyNews',
              'Get the latest news headlines for a company as JSON string',
              Schema(
                SchemaType.string,
                properties: {
                  'ticker': Schema.string(
                    description: 'Stock ticker symbol for a company',
                  ),
                },
                requiredProperties: ['ticker'],
              ),
            ),
            FunctionDeclaration(
              'getNewsWithSentiment',
              'Gets live and historical market news and sentiment data',
              Schema(
                SchemaType.string,
                properties: {
                  'newsTopic': Schema.string(
                    description: '''
News topic to learn about. Supported topics
include blockchain, earnings, ipo,
mergers_and_acquisitions, financial_markets,
economy_fiscal, economy_monetary, economy_macro,
energy_transportation, finance, life_sciences,
manufacturing, real_estate, retail_wholesale,
and technology''',
                  ),
                },
              ),
            ),
          ],
        ),
      );
    }

    return tools;
  }

  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final alphaVantageAccessKey = preferences?.alphaVantageAccessKey ?? '';
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
      'webSearch' => {
          'query': await _webSearch(call.args),
        },
      'getStockPrice' => {
          'stockPrice': _getStockPrice(call.args, alphaVantageAccessKey),
        },
      'getCompanyOverview' => {
          'companyOverview': _getCompanyOverview(
            call.args,
            alphaVantageAccessKey,
          ),
        },
      'getCompanyNews' => {
          'companyNews': _getCompanyNews(call.args, alphaVantageAccessKey),
        },
      'getNewsWithSentiment' => {
          'newsWithSentiment': _getNewsWithSentiment(
            call.args,
            alphaVantageAccessKey,
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
    const frankfurterBaseUrl = 'https://api.frankfurter.app';
    final formattedDate = currencyRequest.currencyDate.format('yyyy-MM-dd');
    final frankfurterUrl = Uri.http(frankfurterBaseUrl, '/$formattedDate', {
      'from': currencyRequest.currencyFrom,
      'to': currencyRequest.currencyTo,
      'amount': currencyRequest.amountFrom,
    });
    final exchangeResult = await http.get(frankfurterUrl);
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

  Future<String> _webSearch(Map<String, Object?> jsonObject) async {
    final query = (jsonObject['query'] ?? '') as String;
    if (query.isNullOrWhiteSpace) {
      return 'N/A';
    }

    // https://stackoverflow.com/questions/37012469/duckduckgo-api-getting-search-results
    const duckDuckGoBaseUrl = 'http://api.duckduckgo.com';
    final duckDuckGoUrl = Uri.http(duckDuckGoBaseUrl, '/', {
      'q': query,
      'format': 'json',
      'no_html': 1,
      'skip_disambig': 1,
    });

    var result = 'N/A';
    final searchResult = await http.get(duckDuckGoUrl);
    if (searchResult.statusCode == 200) {
      final resultJson = json.decode(searchResult.body) as Map<String, dynamic>;
      if (resultJson.containsKey('AbstractText')) {
        result = resultJson['AbstractText'] as String;
      } else if (resultJson.containsKey('Abstract')) {
        result = resultJson['Abstract'] as String;
      }

      if (resultJson.containsKey('AbstractSource') ||
          resultJson.containsKey('AbstractURL')) {
        result += ' (source: ';
        if (resultJson.containsKey('AbstractSource')) {
          result += resultJson.containsKey('AbstractSource') as String;
        }

        if (resultJson.containsKey('AbstractURL')) {
          if (resultJson.containsKey('AbstractSource')) {
            result += ', url: ';
          }

          result += resultJson.containsKey('AbstractURL') as String;
        }

        result += ')';
      }
    }

    return result;
  }

  Future<String> _getStockPrice(
    Map<String, Object?> jsonObject,
    String alphaVantageAccessKey,
  ) async {
    final ticker = (jsonObject['ticker'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace || ticker.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.http(alphaVantageBaseUrl, alphaVantagePath, {
      'function': 'GLOBAL_QUOTE',
      'symbol': ticker,
      'apikey': alphaVantageAccessKey,
    });

    final queryResult = await http.get(alphaVantageUrl);
    if (queryResult.statusCode == 200) {
      return queryResult.body;
    }

    return 'N/A';
  }

  Future<String> _getCompanyOverview(
    Map<String, Object?> jsonObject,
    String alphaVantageAccessKey,
  ) async {
    final ticker = (jsonObject['ticker'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace || ticker.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.http(alphaVantageBaseUrl, alphaVantagePath, {
      'function': 'OVERVIEW',
      'symbol': ticker,
      'apikey': alphaVantageAccessKey,
    });

    final queryResult = await http.get(alphaVantageUrl);
    if (queryResult.statusCode == 200) {
      return queryResult.body;
    }

    return 'N/A';
  }

  Future<String> _getCompanyNews(
    Map<String, Object?> jsonObject,
    String alphaVantageAccessKey,
  ) async {
    final ticker = (jsonObject['ticker'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace || ticker.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.http(alphaVantageBaseUrl, alphaVantagePath, {
      'function': 'NEWS_SENTIMENT',
      'tickers': ticker,
      'limit': 20,
      'sort': 'RELEVANCE',
      'apikey': alphaVantageAccessKey,
    });

    final queryResult = await http.get(alphaVantageUrl);
    if (queryResult.statusCode == 200) {
      return queryResult.body;
    }

    return 'N/A';
  }

  Future<String> _getNewsWithSentiment(
    Map<String, Object?> jsonObject,
    String alphaVantageAccessKey,
  ) async {
    final newsTopic = (jsonObject['newsTopic'] ?? '') as String;
    if (newsTopic.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.http(alphaVantageBaseUrl, alphaVantagePath, {
      'function': 'NEWS_SENTIMENT',
      'topics': newsTopic,
      'limit': 20,
      'sort': 'RELEVANCE',
      'apikey': alphaVantageAccessKey,
    });

    final queryResult = await http.get(alphaVantageUrl);
    if (queryResult.statusCode == 200) {
      return queryResult.body;
    }

    return 'N/A';
  }
}
