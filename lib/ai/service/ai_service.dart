import 'dart:developer';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:inspector_gadget/ai/prompts/closing_parts.dart';
import 'package:inspector_gadget/ai/prompts/history_rag_stuffing.dart';
import 'package:inspector_gadget/ai/prompts/personalization_rag_stuffing.dart';
import 'package:inspector_gadget/ai/prompts/request_instruction.dart';
import 'package:inspector_gadget/ai/prompts/resolver_few_shot.dart';
import 'package:inspector_gadget/ai/prompts/system_instruction.dart';
import 'package:inspector_gadget/ai/prompts/translate_instruction.dart';
import 'package:inspector_gadget/ai/service/firebase_mixin.dart';
import 'package:inspector_gadget/ai/service/generated_content_response.dart';
import 'package:inspector_gadget/ai/tools/tools_mixin.dart';
import 'package:inspector_gadget/camera/service/m_file.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/service/database.dart';
import 'package:inspector_gadget/heart_rate/service/heart_rate.dart';
import 'package:inspector_gadget/interaction/view/interaction_page.dart';
import 'package:inspector_gadget/location/service/location.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';
import 'package:strings/strings.dart';
import 'package:translator/translator.dart';

class AiService with FirebaseMixin, ToolsMixin {
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
    return FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-$modelType',
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
    List<MFile> mediaFiles,
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
        // TODO(MrCsabaToth): extend the history (let's say 2 interaction
        // before and after) around the picked ones
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
    final p13Stuffing = StringBuffer();
    if (nearestP13ns.isNotEmpty) {
      log('P13n ANN Peers ${nearestP13ns.map((p) => p.score)}');
      final annThreshold = preferences.personalizationRagThreshold;
      for (final personalization
          in nearestP13ns.where((p) => p.score < annThreshold)) {
        p13Stuffing.writeln(
          '<personalFact>${personalization.object.content}</personalFact>',
        );
      }
    }

    final gpsLocation = await GetIt.I.get<LocationService>().obtain();
    p13Stuffing
      ..write(
        "<personalFact>User's current immediate location: ",
      )
      ..write(
        '{"lat": ${gpsLocation.latitude}, ',
      )
      ..writeln(
        '"lon": ${gpsLocation.longitude}}</personalFact>',
      );

    if (preferences.measureHeartRate) {
      final heartRate = GetIt.I.get<HeartRateService>().heartRate;
      p13Stuffing.writeln(
        "<personalFact>User's current heart rate: $heartRate</personalFact>",
      );
    }

    stuffedPrompt
      ..writeln(
        p13nStuffingTemplate.replaceAll(
          p13nRagStuffingVariable,
          p13Stuffing.toString(),
        ),
      )
      ..write(
        requestInstructionTemplate.replaceAll(
          requestInstructionVariable,
          prompt,
        ),
      )
      ..write(closingInstructions);

    final stuffed = stuffedPrompt.toString();
    debugPrint('stuffed: $stuffed');
    // TODO(MrCsabaToth): +prompt for media transcription + store in history
    var message = Content.text('');
    if (mediaFiles.isEmpty) {
      message = Content.text(stuffed);
    } else {
      final parts = <Part>[];
      final bucket = FirebaseStorage.instance.bucket;
      for (final mediumFile in mediaFiles) {
        debugPrint('medium: ${mediumFile.xFile.path} (${mediumFile.mimeType})');
        if (!mediumFile.mimeTypeIsUnknown()) {
          final fileName = mediumFile.xFile.path.split('/').last;
          final fileRef = FirebaseStorage.instance.ref(fileName);
          try {
            // Check if already uploaded
            await fileRef.getDownloadURL();
          } catch (e) {
            // Not uploaded yet
            debugPrint('Not uploaded yet? $e');
            await fileRef.putFile(mediumFile.file);
          }

          final fileUri = 'gs://$bucket/${fileRef.fullPath}';
          debugPrint('Storage URI: $fileUri');
          parts.add(FileData(mediumFile.mimeType, fileUri));
        }
      }

      if (parts.isNotEmpty) {
        parts.add(TextPart(stuffed));
        message = Content.multi(parts);
      } else {
        message = Content.text(stuffed);
      }
    }

    var response = GenerateContentResponse([], null);
    try {
      response = await chat.sendMessage(message);
    } catch (e) {
      log('Exception during chat.sendMessage: $e');
      return null;
    }

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
      try {
        response = await chat.sendMessage(content);
      } catch (e) {
        log('Exception during function iteration chat.sendMessage: $e');
        return null;
      }
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
    final model = FirebaseVertexAI.instance.generativeModel(
      model: 'text-embedding-004', // 'text-multilingual-embedding-002',
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
