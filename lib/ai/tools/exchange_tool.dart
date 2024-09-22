import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/tools/currency_request.dart';
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

class ExchangeTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesService preferences) {
    return true;
  }

  @override
  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesService preferences,
  ) {
    return [
      FunctionDeclaration(
        'fetchCurrencyExchangeRate',
        'Fetch the exchange rate between two currencies.',
        Schema(
          SchemaType.object,
          properties: {
            'currencyDate': Schema.string(
              description: 'A date or the value "latest" '
                  'if a time period is not specified',
            ),
            'currencyFrom': Schema.string(
              description: 'The currency to convert from in ISO 4217 format',
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
      FunctionDeclaration(
        'fetchCryptoExchangeRate',
        'Fetch the immediate exchange rate between two crypto currencies '
            'or a crypto currency and a money currency.',
        Schema(
          SchemaType.object,
          properties: {
            'cryptoFromTicker': Schema.string(
              description: 'The crypto currency ticker symbol to convert from',
            ),
            'currencyToTicker': Schema.string(
              description: 'The money currency to convert to in ISO 4217 '
                  'format or crypto currency ticker symbol',
            ),
          },
          requiredProperties: ['cryptoFromTicker', 'currencyToTicker'],
        ),
      ),
    ];
  }

  @override
  Tool getTool(PreferencesService preferences) {
    return Tool(
      functionDeclarations: getFunctionDeclarations(preferences),
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return ['fetchCurrencyExchangeRate', 'fetchCryptoExchangeRate']
        .contains(call.name);
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    PreferencesService preferences,
  ) async {
    final result = switch (call.name) {
      'fetchCurrencyExchangeRate' => {
          'exchangeRate': await _fetchCurrencyExchangeRate(
            CurrencyRequest.fromJson(call.args),
          ),
        },
      'fetchCryptoExchangeRate' => {
          'exchangeRate': await _fetchCryptoExchangeRate(
            CurrencyRequest.fromJson(call.args),
          ),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  Future<double> _fetchCurrencyExchangeRate(
    CurrencyRequest currencyRequest,
  ) async {
    const frankfurterBaseUrl = 'api.frankfurter.app';
    final formattedDate = currencyRequest.currencyDate.format('yyyy-MM-dd');
    final frankfurterUrl = Uri.https(frankfurterBaseUrl, '/$formattedDate', {
      'from': currencyRequest.currencyFrom,
      'to': currencyRequest.currencyTo,
      'amount': currencyRequest.amountFrom.toString(),
    });
    final exchangeResult = await http.get(frankfurterUrl);
    if (exchangeResult.statusCode == 200) {
      final exchangeJson =
          json.decode(exchangeResult.body) as Map<String, dynamic>;
      if (exchangeJson.containsKey('rates')) {
        final rates = exchangeJson['rates'] as Map<String, dynamic>;
        if (rates.containsKey(currencyRequest.currencyTo)) {
          return rates[currencyRequest.currencyTo]! as double;
        }
      }
    }

    return 0.0;
  }

  Future<double> _fetchCryptoExchangeRate(
    CurrencyRequest currencyRequest,
  ) async {
    const cryptoCompareBaseUrl = 'min-api.cryptocompare.com';
    const cryptoComparePath = '/data/price';
    final cryptoCompareUrl =
        Uri.https(cryptoCompareBaseUrl, cryptoComparePath, {
      'fsym': currencyRequest.currencyFrom,
      'tsyms': currencyRequest.currencyTo,
    });
    final exchangeResult = await http.get(cryptoCompareUrl);
    if (exchangeResult.statusCode == 200) {
      final exchangeJson =
          json.decode(exchangeResult.body) as Map<String, dynamic>;
      if (exchangeJson.containsKey(currencyRequest.currencyTo)) {
        return exchangeJson[currencyRequest.currencyTo]! as double;
      }
    }

    return 0.0;
  }
}
