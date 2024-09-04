import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/ai/prompts/closing_parts.dart';
import 'package:inspector_gadget/ai/prompts/history_rag_stuffing.dart';
import 'package:inspector_gadget/ai/prompts/personalization_rag_stuffing.dart';
import 'package:inspector_gadget/ai/prompts/request_instruction.dart';
import 'package:inspector_gadget/ai/prompts/resolver_few_shot.dart';
import 'package:inspector_gadget/ai/prompts/system_instruction.dart';
import 'package:inspector_gadget/ai/prompts/translate_instruction.dart';
import 'package:inspector_gadget/ai/service/generated_content_response.dart';
import 'package:inspector_gadget/ai/tools/tools_mixin.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:mime/mime.dart';
import 'package:strings/strings.dart';
import 'package:translator/translator.dart';

class AiService with ToolsMixin {
  AiService() {
    watermark = DateTime.now();
  }

  late DateTime watermark;
  ChatSession? chatSession;

  GenerativeModel getModel(
    String systemInstruction, {
    bool withTools = true,
  }) {
    final preferences = GetIt.I.get<PreferencesService>();
    final modelType = preferences.fastLlmMode ? 'flash' : 'pro';
    return GenerativeModel(
      model: 'gemini-1.5-$modelType-preview',
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

  ChatSession? getChatSession(
    String systemInstruction, {
    bool withTools = true,
  }) {
    if (chatSession == null) {
      debugPrint('systemInstruction: $systemInstructionTemplate');
      final model = getModel(systemInstructionTemplate, withTools: withTools);
      chatSession = model.startChat();
      watermark = DateTime.now();
    }

    return chatSession;
  }

  Future<int> persistModelResponse(
    DatabaseService database,
    InteractionMode mode,
    String response,
    String locale,
  ) async {
    if (response.isEmpty) {
      return -1;
    }

    final modelEmbedding = await obtainEmbedding(response);
    return database.addUpdateHistory(
      History(
        'model',
        mode.toString(),
        response,
        locale,
        '',
        modelEmbedding,
      ),
    );
  }

  Future<String> persistedHistoryString(
    DatabaseService database,
    int limit,
  ) async {
    final historyList = await database.limitedHistory(100, watermark);
    final buffer = StringBuffer();
    for (final utterance in historyList) {
      buffer.writeln('${utterance.role}: ${utterance.content}');
    }

    return buffer.toString();
  }

  Future<GenerateContentResponse?> chatStep(
    String prompt,
    String mediaPath,
    InteractionMode interactionMode,
  ) async {
    debugPrint('prompt: $prompt');
    final chat = getChatSession(systemInstructionTemplate);
    if (chat == null) {
      return null;
    }

    final preferences = GetIt.I.get<PreferencesService>();
    final database = GetIt.I.get<DatabaseService>();
    final history = await persistedHistoryString(database, 100);
    final resolved = await resolvePromptToStandAlone(prompt, history);
    final userEmbedding = await obtainEmbedding(resolved);
    database.addUpdateHistory(
      History(
        'user',
        interactionMode.toString(),
        prompt,
        PreferencesService.inputLocaleDefault,
        resolved,
        userEmbedding,
      ),
    );
    final stuffedPrompt = StringBuffer();
    final nearestHistory =
        await database.getNearestHistory(userEmbedding, watermark);
    if (nearestHistory.isNotEmpty) {
      log('History ANN Peers ${nearestHistory.map((p) => p.score)}');
      final annThreshold = preferences.historyRagThreshold;
      final historyStuffing = StringBuffer();
      for (final history
          in nearestHistory.where((h) => h.score < annThreshold)) {
        historyStuffing.writeln('<history>${history.object.role}: '
            '${history.object.content}</history>');
      }

      if (historyStuffing.isNotEmpty) {
        stuffedPrompt.writeln(
          historyRagStuffingTemplate.replaceAll(
            historyRagStuffingVariable,
            historyStuffing.toString(),
          ),
        );
      }
    }

    final nearestP13ns =
        await database.getNearestPersonalization(userEmbedding);
    if (nearestP13ns.isNotEmpty) {
      log('P13n ANN Peers ${nearestP13ns.map((p) => p.score)}');
      final annThreshold = preferences.personalizationRagThreshold;
      final p13Stuffing = StringBuffer();
      for (final personalization
          in nearestP13ns.where((p) => p.score < annThreshold)) {
        p13Stuffing.writeln(
          '<personalFact>${personalization.object.content}</personalFact>',
        );
      }

      if (p13Stuffing.isNotEmpty) {
        stuffedPrompt.writeln(
          p13nStuffingTemplate.replaceAll(
            p13nRagStuffingVariable,
            p13Stuffing.toString(),
          ),
        );
      }
    }

    stuffedPrompt
      ..write(
        requestInstructionTemplate.replaceAll(
          requestInstructionVariable,
          prompt,
        ),
      )
      ..write(closingInstructions);

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

    var response = await chat.sendMessage(message);

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
      response = await chat.sendMessage(content);
    }

    if (response.text != null && response.text!.isNotEmpty) {
      await persistModelResponse(
        database,
        interactionMode,
        response.strippedText(),
        PreferencesService.inputLocaleDefault,
      );
    }

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
      model: 'text-embedding-004',
      apiKey: preferences.geminiApiKey,
    );
    final content = Content.text(prompt);
    final embeddingResult = await model.embedContent(content);

    return dimensionalityReduction(embeddingResult.embedding.values);
  }

  String nativeHistoryToString(Iterable<Content> history) {
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
    final model = getModel(resolverSystemInstruction, withTools: false);
    final nearHistory = nativeHistoryToString(chatSession?.history ?? []);
    final fullHistory = history + nearHistory;
    final stuffedPrompt = resolverFewShotTemplate.replaceAll(
      resolverFewShotVariable,
      fullHistory,
    );
    final content = Content.text(stuffedPrompt);
    final response = await model.generateContent([content]);

    return response.text ?? '';
  }

  Future<GenerateContentResponse?> translate(
    String transcript,
    String sourceLocale,
    String targetLocale,
  ) async {
    final database = GetIt.I.get<DatabaseService>();
    final userEmbedding = await obtainEmbedding(transcript);
    database.addUpdateHistory(
      History(
        'user',
        InteractionMode.translate.toString(),
        transcript,
        sourceLocale,
        '',
        userEmbedding,
      ),
    );

    final preferences = GetIt.I.get<PreferencesService>();
    if (preferences.classicGoogleTranslate) {
      final translator = GoogleTranslator();
      final translation =
          await translator.translate(transcript, to: targetLocale.left(2));
      await persistModelResponse(
        database,
        InteractionMode.translate,
        translation.text,
        targetLocale,
      );
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

    final chat = getChatSession(systemInstructionTemplate, withTools: false);
    if (chat == null) {
      return null;
    }

    final stuffedPrompt = translateInstruction
        .replaceAll(translationSubjectVariable, transcript)
        .replaceAll(translationTargetLocaleVariable, targetLocale);
    final content = Content.text(stuffedPrompt);
    final response = await chat.sendMessage(content);

    if (response.text != null && response.text!.isNotEmpty) {
      await persistModelResponse(
        database,
        InteractionMode.translate,
        response.strippedText(),
        targetLocale,
      );
    }

    return response;
  }
}
