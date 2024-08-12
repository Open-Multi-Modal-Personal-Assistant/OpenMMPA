import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/ai/prompts/resolver_few_shot.dart';
import 'package:inspector_gadget/ai/prompts/stuffed_user_utterance.dart';
import 'package:inspector_gadget/ai/prompts/system_instruction.dart';
import 'package:inspector_gadget/ai/prompts/translate_instruction.dart';
import 'package:inspector_gadget/ai/tools/tools_mixin.dart';
import 'package:inspector_gadget/database/cubit/database_cubit.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';
import 'package:inspector_gadget/secrets.dart';

class AiCubit extends Cubit<int> with ToolsMixin {
  AiCubit() : super(0);

  ChatSession? chat;

  GenerativeModel getModel(
    PreferencesState? preferencesState,
    String systemInstruction, {
    bool withTools = true,
  }) {
    final fastMode =
        preferencesState?.fastLlmMode ?? PreferencesState.fastLlmModeDefault;
    final modelType = fastMode ? 'flash' : 'pro';
    return GenerativeModel(
      model: 'gemini-1.5-$modelType',
      apiKey: preferencesState?.geminiApiKey ?? geminiApiKey,
      systemInstruction: Content.text(systemInstruction),
      tools: withTools ? [getFunctionDeclarations(preferencesState)] : null,
    );
  }

  Future<GenerateContentResponse?> chatStep(
    String prompt,
    String imagePath,
    DatabaseCubit? database,
    PreferencesState? preferencesState,
    int heartRate,
    Location? gpsLocation,
  ) async {
    log('prompt: $prompt');
    if (chat != null) {
      final stuffedInstruction = systemInstruction.replaceAll(
        '%%%',
        getFunctionCallPromptStuffing(preferencesState),
      );
      log('stuffedInstruction: $stuffedInstruction');
      final model = getModel(preferencesState, stuffedInstruction);
      chat = model.startChat();
    }

    if (chat == null) {
      return null;
    }

    final history = await database?.limitedHistoryString(100) ?? '';
    final resolved =
        await resolvePromptToStandAlone(prompt, history, preferencesState);
    final userEmbedding = await obtainEmbedding(resolved, preferencesState);
    database?.addUpdateHistory(
      History(
        'user',
        prompt,
        PreferencesState.inputLocaleDefault,
        resolved,
        userEmbedding,
      ),
    );
    final stuffedPrompt = StringBuffer();
    final nearestHistory = await database?.getNearestHistory(userEmbedding);
    if (nearestHistory != null && nearestHistory.isNotEmpty) {
      stuffedPrompt
        ..writeln(conversationStuffing)
        ..writeln(
          nearestHistory.map((h) => '${h.object.role}: ${h.object.content}'),
        );
    }

    final nearestPersonalization =
        await database?.getNearestPersonalization(userEmbedding);
    if (nearestPersonalization != null && nearestPersonalization.isNotEmpty) {
      stuffedPrompt
        ..writeln(personalizationStuffing)
        ..writeln(nearestPersonalization.map((p) => '* ${p.object.content}'));
    }

    if (stuffedPrompt.isNotEmpty) {
      stuffedPrompt.write(questionStuffing);
    }

    stuffedPrompt.write(prompt);

    final stuffed = stuffedPrompt.toString();
    log('stuffed: $stuffed');
    var message = Content.text('');
    if (imagePath.isEmpty) {
      message = Content.text(stuffed);
    } else {
      Content.multi([
        TextPart(stuffed),
        // TODO(MrCsabaToth): other image formats (png, jpg, webp, heic, heif)
        DataPart('image/jpeg', await File(imagePath).readAsBytes()),
      ]);
    }

    var response = await chat!.sendMessage(message);

    List<FunctionCall> functionCalls;
    var content = Content.text('');
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
      // TODO(MrCsabaToth): Store in history?
      response = await chat!.sendMessage(content);
    }

    final modelEmbedding =
        await obtainEmbedding(response.text ?? '', preferencesState);
    database?.addUpdateHistory(
      History(
        'model',
        response.text ?? '',
        PreferencesState.inputLocaleDefault,
        '',
        modelEmbedding,
      ),
    );

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

  String historyToString(Iterable<Content> history) {
    final buffer = StringBuffer();
    for (final utterance in history) {
      buffer.writeln('${utterance.role}: $utterance');
    }

    return buffer.toString();
  }

  Future<String> resolvePromptToStandAlone(
    String prompt,
    String history,
    PreferencesState? preferencesState,
  ) async {
    final fastMode =
        preferencesState?.fastLlmMode ?? PreferencesState.fastLlmModeDefault;
    final modelType = fastMode ? 'flash' : 'pro';
    final model = GenerativeModel(
      model: 'gemini-1.5-$modelType',
      apiKey: preferencesState?.geminiApiKey ?? geminiApiKey,
    );

    final nearHistory = historyToString(chat?.history ?? []);
    final fullHistory = history + nearHistory;
    final stuffedPrompt = resolverFewShotPrompt.replaceAll('%%%', fullHistory);
    final content = Content.text(stuffedPrompt);
    final response = await model.generateContent([content]);

    return response.text ?? '';
  }

  Future<GenerateContentResponse?> translate(
    String transcript,
    String targetLocale,
    PreferencesState? preferencesState,
  ) async {
    final model = getModel(
      preferencesState,
      translateSystemInstruction,
      withTools: false,
    );
    final stuffedPrompt = translateInstruction.replaceAll('%%%', targetLocale);
    final content = Content.text(stuffedPrompt + transcript);
    final response = await model.generateContent([content]);
    return response;
  }
}
