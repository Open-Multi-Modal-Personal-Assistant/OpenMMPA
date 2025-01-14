import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

class AlphaVantageTool implements FunctionTool {
  static const String alphaVantageBaseUrl = 'www.alphavantage.co';
  static const String alphaVantagePath = '/query';

  String alphaVantageAccessKey = '';

  @override
  bool isAvailable(PreferencesService preferences) {
    return preferences.alphaVantageAccessKey.isNullOrWhiteSpace;
  }

  @override
  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesService preferences,
  ) {
    if (!isAvailable(preferences)) {
      return [];
    }

    return [
      FunctionDeclaration(
        'fetchStockPrice',
        'Fetch the current stock price of a given company in JSON string',
        parameters: {
          'ticker': Schema.string(
            description: 'Stock ticker symbol for a company',
          ),
        },
      ),
      FunctionDeclaration(
        'fetchCompanyOverview',
        'Fetch company details and other financial data in JSON string',
        parameters: {
          'ticker': Schema.string(
            description: 'Stock ticker symbol for a company',
          ),
        },
      ),
      FunctionDeclaration(
        'fetchCompanyNews',
        'Fetch the latest news headlines for a company as JSON string',
        parameters: {
          'ticker': Schema.string(
            description: 'Stock ticker symbol for a company',
          ),
        },
      ),
      FunctionDeclaration(
        'fetchNewsWithSentiment',
        'Fetch live and historical market news and sentiment data',
        parameters: {
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
    ];
  }

  @override
  Tool getTool(PreferencesService preferences) {
    var functions = <FunctionDeclaration>[];
    if (isAvailable(preferences)) {
      functions = getFunctionDeclarations(preferences);
    }

    return Tool.functionDeclarations(functions);
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return [
      'fetchStockPrice',
      'fetchCompanyOverview',
      'fetchCompanyNews',
      'fetchNewsWithSentiment',
    ].contains(call.name);
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    PreferencesService preferences,
  ) async {
    alphaVantageAccessKey = preferences.alphaVantageAccessKey;
    final result = switch (call.name) {
      'fetchStockPrice' => {
          'stockPrice': _getStockPrice(call.args),
        },
      'fetchCompanyOverview' => {
          'companyOverview': _getCompanyOverview(call.args),
        },
      'fetchCompanyNews' => {
          'companyNews': _getCompanyNews(call.args),
        },
      'fetchNewsWithSentiment' => {
          'newsWithSentiment': _getNewsWithSentiment(call.args),
        },
      _ => <String, String>{}
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
      'limit': '20',
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
      'limit': '20',
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
