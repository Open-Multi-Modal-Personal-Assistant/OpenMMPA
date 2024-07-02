import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/utterance/tools/function_tool.dart';

class LyricsTool implements FunctionTool {
  @override
  bool isAvailable(PreferencesState? preferences) {
    return true;
  }

  @override
  Tool getTool(PreferencesState? preferences) {
    return Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'lyricsLookup',
          'Look up a lyrics of a song by a given artist and title',
          Schema(
            SchemaType.string,
            properties: {
              'artist': Schema.string(
                description: 'The artist of the song',
              ),
              'title': Schema.string(
                description: 'The title of the song',
              ),
            },
            requiredProperties: ['artist', 'title'],
          ),
        ),
      ],
    );
  }

  @override
  bool canDispatchFunctionCall(FunctionCall call) {
    return call.name == 'lyricsLookup';
  }

  @override
  Future<FunctionResponse> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    final result = switch (call.name) {
      'lyricsLookup' => {
          'query': await _lyricsLookup(call.args),
        },
      _ => null
    };

    return FunctionResponse(call.name, result);
  }

  Future<String> _lyricsLookup(Map<String, Object?> jsonObject) async {
    final artist = (jsonObject['artist'] ?? '') as String;
    final title = (jsonObject['title'] ?? '') as String;
    if (artist.isNullOrWhiteSpace || title.isNullOrWhiteSpace) {
      return 'N/A';
    }

    const lyricsApiBaseUrl = 'https://api.lyrics.ovh';
    final lyricsApiPath = '/v1/$artist/$title';
    final lyricsApiUrl = Uri.http(lyricsApiBaseUrl, lyricsApiPath);

    final searchResult = await http.get(lyricsApiUrl);
    if (searchResult.statusCode == 200) {
      final resultJson = json.decode(searchResult.body) as Map<String, dynamic>;
      if (resultJson.containsKey('lyrics')) {
        return resultJson['lyrics'] as String;
      }
    }

    return 'N/A';
  }
}
