import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/utterance/tools/currency_request.dart';
import 'package:inspector_gadget/utterance/tools/function_tool.dart';

class ExchangeTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return true;
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    return Tool(
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
      ],
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return call.name == 'fetchCurrencyExchangeRate';
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final result = switch (call.name) {
      'fetchCurrencyExchangeRate' => {
          'exchangeRate': await _fetchCurrencyExchangeRate(
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
}
