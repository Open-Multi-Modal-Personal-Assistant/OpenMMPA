import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/ai/prompts/resolver_few_shot.dart';
import 'package:inspector_gadget/ai/prompts/stuffed_user_utterance.dart';
import 'package:inspector_gadget/ai/prompts/system_instruction.dart';
import 'package:inspector_gadget/ai/prompts/translate_instruction.dart';
import 'package:inspector_gadget/ai/tools/tools_mixin.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:mime/mime.dart';
import 'package:strings/strings.dart';
import 'package:translator/translator.dart';

class AiService with ToolsMixin {
  ChatSession? chat;

  GenerativeModel getModel(
    String systemInstruction, {
    bool withTools = true,
  }) {
    final preferences = GetIt.I.get<PreferencesService>();
    final modelType = preferences.fastLlmMode ? 'flash' : 'pro';
    return GenerativeModel(
      model: 'gemini-1.5-$modelType',
      apiKey: preferences.geminiApiKey,
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          preferences.harmCategoryHarassment,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          preferences.harmCategoryHateSpeech,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          preferences.harmCategorySexuallyExplicit,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          preferences.harmCategoryDangerousContent,
        ),
      ],
      systemInstruction: Content.text(systemInstruction),
      tools: withTools ? [getFunctionDeclarations(preferences)] : null,
    );
  }

  Future<GenerateContentResponse?> chatStep(
    String prompt,
    String mediaPath,
  ) async {
    debugPrint('prompt: $prompt');
    final preferences = GetIt.I.get<PreferencesService>();
    if (chat == null) {
      final stuffedInstruction = systemInstruction.replaceAll(
        '%%%',
        getFunctionCallPromptStuffing(preferences),
      );
      debugPrint('stuffedInstruction: $stuffedInstruction');
      final model = getModel(stuffedInstruction);
      chat = model.startChat();
    }

    if (chat == null) {
      return null;
    }

    final database = GetIt.I.get<DatabaseService>();
    final history = await database.limitedHistoryString(100);
    final resolved = await resolvePromptToStandAlone(prompt, history);
    final userEmbedding = await obtainEmbedding(resolved);
    database.addUpdateHistory(
      History(
        'user',
        prompt,
        PreferencesService.inputLocaleDefault,
        resolved,
        userEmbedding,
      ),
    );
    final stuffedPrompt = StringBuffer();
    final nearestHistory = await database.getNearestHistory(userEmbedding);
    if (nearestHistory.isNotEmpty) {
      log('ANN Peers ${nearestHistory.map((p) => p.score)}');
      final annThreshold = preferences.historyRagThreshold;
      stuffedPrompt.writeln(conversationStuffing);
      for (final history
          in nearestHistory.where((h) => h.score < annThreshold)) {
        stuffedPrompt
            .writeln('- ${history.object.role}: ${history.object.content}');
      }
    }

    final nearestPersonalization =
        await database.getNearestPersonalization(userEmbedding);
    if (nearestPersonalization.isNotEmpty) {
      log('ANN Peers ${nearestPersonalization.map((p) => p.score)}');
      final annThreshold = preferences.personalizationRagThreshold;
      stuffedPrompt.writeln(personalizationStuffing);
      for (final personalization
          in nearestPersonalization.where((p) => p.score < annThreshold)) {
        stuffedPrompt.writeln('- ${personalization.object.content}');
      }
    }

    if (stuffedPrompt.isNotEmpty) {
      stuffedPrompt.write(questionStuffing);
    }

    stuffedPrompt.write(prompt);

    final stuffed = stuffedPrompt.toString();
    debugPrint('stuffed: $stuffed');
    var message = Content.text('');
    debugPrint('mediaPath: $mediaPath');
    if (mediaPath.isEmpty) {
      message = Content.text(stuffed);
    } else {
      final mediaContent = await File(mediaPath).readAsBytes();
      final mimeType = lookupMimeType(
        mediaPath,
        headerBytes: mediaContent.take(16).toList(growable: false),
      );
      if (mimeType != null) {
        message = Content.multi(
          [TextPart(stuffed), DataPart(mimeType, mediaContent)],
        );
      } else {
        message = Content.text(stuffed);
      }
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
          final gpsLocation = await GetIt.I.get<LocationService>().obtain();
          final heartRate = GetIt.I.get<HeartRateService>().heartRate;
          final response = await dispatchFunctionCall(
            functionCall,
            gpsLocation,
            heartRate,
            preferences,
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

    final modelEmbedding = await obtainEmbedding(response.text ?? '');
    database.addUpdateHistory(
      History(
        'model',
        response.text ?? '',
        PreferencesService.inputLocaleDefault,
        '',
        modelEmbedding,
      ),
    );

    return response;
  }

  List<double> dimensionalityReduction(List<double> vector) {
    // Reduction by addition of values
    final foldedVector =
        vector.take(embeddingDimensionality).toList(growable: false);
    if (vector.length > embeddingDimensionality) {
      for (var i = 0, j = embeddingDimensionality;
          j < vector.length;
          i++, j++) {
        foldedVector[i % embeddingDimensionality] += vector[j];
      }
    }

    return foldedVector;
  }

  Future<List<double>> obtainEmbedding(String prompt) async {
    final preferences = GetIt.I.get<PreferencesService>();
    final model = GenerativeModel(
      model: 'text-multilingual-embedding-002',
      apiKey: preferences.geminiApiKey,
    );
    final content = Content.text(prompt);
    final embeddingResult = await model.embedContent(content);

    return dimensionalityReduction(embeddingResult.embedding.values);
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
  ) async {
    final preferences = GetIt.I.get<PreferencesService>();
    final modelType = preferences.fastLlmMode ? 'flash' : 'pro';
    final model = GenerativeModel(
      model: 'gemini-1.5-$modelType',
      apiKey: preferences.geminiApiKey,
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
  ) async {
    final preferences = GetIt.I.get<PreferencesService>();
    if (preferences.classicGoogleTranslate) {
      final translator = GoogleTranslator();
      final translation =
          await translator.translate(transcript, to: targetLocale.left(2));
      return GenerateContentResponse(
        [
          Candidate(
            Content.text(translation.text),
            [
              SafetyRating(
                HarmCategory.harassment,
                HarmProbability.negligible,
              ),
              SafetyRating(
                HarmCategory.hateSpeech,
                HarmProbability.negligible,
              ),
              SafetyRating(
                HarmCategory.sexuallyExplicit,
                HarmProbability.negligible,
              ),
              SafetyRating(
                HarmCategory.dangerousContent,
                HarmProbability.negligible,
              ),
            ],
            CitationMetadata([]),
            FinishReason.stop,
            '',
          ),
        ],
        null,
      );
    }

    final model = getModel(translateSystemInstruction, withTools: false);
    final stuffedPrompt = translateInstruction.replaceAll('%%%', targetLocale);
    final content = Content.text(stuffedPrompt + transcript);
    final response = await model.generateContent([content]);
    return response;
  }
}
