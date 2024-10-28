import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

class WebSearchTool implements FunctionTool {
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
        'webSearch',
        'Search the web and wikipedia for facts about any topic or '
            'gather munition to answer any questions',
        parameters: {
          'query': Schema.string(
            description: 'The search query or question which need '
                'to be researched or answered',
          ),
        },
      ),
    ];
  }

  @override
  Tool getTool(PreferencesService preferences) {
    return Tool.functionDeclarations(
      getFunctionDeclarations(preferences),
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return call.name == 'webSearch';
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    PreferencesService preferences,
  ) async {
    final result = switch (call.name) {
      'webSearch' => {
          'query': await _webSearch(call.args),
        },
      _ => <String, String>{}
    };

    return FunctionResponse(call.name, result);
  }

  Future<String> _webSearch(Map<String, Object?> jsonObject) async {
    final query = (jsonObject['query'] ?? '') as String;
    if (query.isNullOrWhiteSpace) {
      return 'N/A';
    }

    // https://stackoverflow.com/questions/37012469/duckduckgo-api-getting-search-results
    const duckDuckGoBaseUrl = 'api.duckduckgo.com';
    final duckDuckGoUrl = Uri.http(duckDuckGoBaseUrl, '/', {
      'q': query,
      'format': 'json',
      'no_html': '1',
      'skip_disambig': '1',
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

      if (result.isNullOrWhiteSpace) {
        // TODO(MrCsabaToth): Try Cloud Function!
        return 'N/A';
      }

      return json.encode({
        'text': result,
        'source': resultJson.tryGetString('AbstractSource'),
        'url': resultJson.tryGetString('AbstractURL'),
      });
    }

    return result;
  }
}
