import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

class WebResearchTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return !(preferences?.tavilyApiKey.isNullOrWhiteSpace ?? false);
  }

  @override
  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesState? preferences,
  ) {
    if (!isAvailable(preferences)) {
      return [];
    }

    return [
      FunctionDeclaration(
        'webResearch',
        'deliver accurate and factual search results quickly and efficiently',
        Schema(
          SchemaType.object,
          properties: {
            'query': Schema.string(
              description: 'The search query or question which need to be '
                  'researched',
            ),
          },
          requiredProperties: ['query'],
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
    return call.name == 'webResearch';
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final tavilyApiKey = preferences?.tavilyApiKey ?? '';
    final result = switch (call.name) {
      'webResearch' => {
          'query': await _webResearch(call.args, tavilyApiKey),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  Future<String> _webResearch(
    Map<String, Object?> jsonObject,
    String tavilyApiKey,
  ) async {
    final query = (jsonObject['query'] ?? '') as String;
    if (query.isNullOrWhiteSpace) {
      return 'N/A';
    }

    const tavilyBaseUrl = 'api.tavily.com';
    final tavilyUrl = Uri.https(tavilyBaseUrl, '/search');

    final requestBodyJson = {
      'api_key': tavilyApiKey,
      'query': query,
      'search_depth': 'basic',
      'include_answer': false,
      'include_images': false,
      'include_raw_content': false,
      'max_results': 1,
    };
    final searchResult = await http.post(
      tavilyUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBodyJson),
    );

    if (searchResult.statusCode == 200) {
      final resultJson = json.decode(searchResult.body) as Map<String, dynamic>;
      if (resultJson.containsKey('results')) {
        final results = resultJson['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final firstResult = results[0] as Map<String, dynamic>;
          return json.encode({
            'title': firstResult.tryGetString('title'),
            'content': firstResult.tryGetString('content'),
            'url': firstResult.tryGetString('url'),
          });
        }
      }
    }

    return 'N/A';
  }
}
