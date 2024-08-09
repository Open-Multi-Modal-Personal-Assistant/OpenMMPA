import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/ai/tools/tools_mixin.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/secrets.dart';

class AiCubit extends Cubit<int> with ToolsMixin {
  AiCubit() : super(0);

  Future<GenerateContentResponse?> chatStep(
    String prompt,
    PreferencesState? preferencesState,
    int heartRate,
    Location? gpsLocation,
  ) async {
    final fastMode =
        preferencesState?.fastLlmMode ?? PreferencesState.fastLlmModeDefault;
    final tools = [getFunctionDeclarations(preferencesState)];
    final modelType = fastMode ? 'flash' : 'pro';
    final model = GenerativeModel(
      model: 'gemini-1.5-$modelType',
      apiKey: preferencesState?.geminiApiKey ?? geminiApiKey,
      tools: tools,
    );
    final chat = model.startChat();

    // TODO(MrCsabaToth): History: https://github.com/google-gemini/generative-ai-dart/blob/main/samples/dart/bin/advanced_chat.dart
    // we still need to roll our own history persistence (there's no sessionId)
    // TODO(MrCsabaToth): Vector DB + embedding for knowledge base
    // Note: ObjectBox supports Vector DB now
    // so we'll use that for both history and RAG
    // TODO(MrCsabaToth): Multi modal call?
    var content = Content.text(prompt);
    var response = await chat.sendMessage(content);

    List<FunctionCall> functionCalls;
    while ((functionCalls = response.functionCalls.toList()).isNotEmpty) {
      final responses = <FunctionResponse>[];
      for (final functionCall in functionCalls) {
        debugPrint('Function call ${functionCall.name}, '
            'params: ${functionCall.args}');
        try {
          final response = await dispatchFunctionCall(
            functionCall,
            gpsLocation,
            heartRate,
            preferencesState,
          );
          debugPrint('Function call result ${response?.response}');
          if (response?.response != null) {
            responses.add(response!);
          }
        } catch (e) {
          log('Exception during transcription: $e');
          return null;
        }
      }

      content = response.candidates.first.content;
      content.parts.addAll(responses);
      response = await chat.sendMessage(content);
    }

    return response;
  }

  Future<List<double>> obtainEmbedding(
    String prompt,
    PreferencesState? preferencesState,
  ) async {
    final model = GenerativeModel(
      model: 'text-embedding-004',
      apiKey: preferencesState?.geminiApiKey ?? geminiApiKey,
    );
    final content = Content.text(prompt);
    final embeddingResult = await model.embedContent(content);

    return embeddingResult.embedding.values;
  }
}
