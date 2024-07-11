import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/interaction/tools/function_tool.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class AlphaVantageTool implements FunctionTool {
  static const String alphaVantageBaseUrl = 'www.alphavantage.co';
  static const String alphaVantagePath = '/query';

  String alphaVantageAccessKey = '';

  @override
  bool isAvailable(PreferencesState? preferences) {
    return !(preferences?.alphaVantageAccessKey.isNullOrWhiteSpace ?? false);
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    var functions = <FunctionDeclaration>[];
    if (isAvailable(preferences)) {
      functions = [
        FunctionDeclaration(
          'getStockPrice',
          'Fetch the current stock price of a given company in JSON string',
          Schema(
            SchemaType.object,
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
            SchemaType.object,
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
            SchemaType.object,
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
            SchemaType.object,
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
            requiredProperties: ['newsTopic'],
          ),
        ),
      ];
    }

    return Tool(functionDeclarations: functions);
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return [
      'getStockPrice',
      'getCompanyOverview',
      'getCompanyNews',
      'getNewsWithSentiment',
    ].contains(call.name);
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    alphaVantageAccessKey = preferences?.alphaVantageAccessKey ?? '';
    final result = switch (call.name) {
      'getStockPrice' => {
          'stockPrice': _getStockPrice(call.args),
        },
      'getCompanyOverview' => {
          'companyOverview': _getCompanyOverview(call.args),
        },
      'getCompanyNews' => {
          'companyNews': _getCompanyNews(call.args),
        },
      'getNewsWithSentiment' => {
          'newsWithSentiment': _getNewsWithSentiment(call.args),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  Future<String> _getStockPrice(Map<String, Object?> jsonObject) async {
    final ticker = (jsonObject['ticker'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace || ticker.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.https(alphaVantageBaseUrl, alphaVantagePath, {
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

  Future<String> _getCompanyOverview(Map<String, Object?> jsonObject) async {
    final ticker = (jsonObject['ticker'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace || ticker.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.https(alphaVantageBaseUrl, alphaVantagePath, {
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

  Future<String> _getCompanyNews(Map<String, Object?> jsonObject) async {
    final ticker = (jsonObject['ticker'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace || ticker.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.https(alphaVantageBaseUrl, alphaVantagePath, {
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

  Future<String> _getNewsWithSentiment(Map<String, Object?> jsonObject) async {
    final newsTopic = (jsonObject['newsTopic'] ?? '') as String;
    if (alphaVantageAccessKey.isNullOrWhiteSpace ||
        newsTopic.isNullOrWhiteSpace) {
      return 'N/A';
    }

    final alphaVantageUrl = Uri.https(alphaVantageBaseUrl, alphaVantagePath, {
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
