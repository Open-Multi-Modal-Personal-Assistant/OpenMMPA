import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:inspector_gadget/ai/tools/alpha_vantage_tool.dart';
import 'package:inspector_gadget/ai/tools/exchange_tool.dart';
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/ai/tools/seven_timer_weather_tool.dart';
import 'package:inspector_gadget/ai/tools/sun_time_tool.dart';
import 'package:inspector_gadget/ai/tools/web_research_tool.dart';
// import 'package:inspector_gadget/ai/tools/web_search_tool.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

mixin ToolsMixin {
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co';
  static const String alphaVantagePath = '/query';

  List<FunctionTool> functionTools = [];

  List<FunctionTool> initializeFunctionTools(PreferencesService preferences) {
    if (functionTools.isNotEmpty) {
      return functionTools;
    }

    functionTools.addAll([
      WeatherTool(),
      SunTimeTool(),
      // WebSearchTool(),
      WebResearchTool(),
      ExchangeTool(),
    ]);

    if (!preferences.alphaVantageAccessKey.isNullOrWhiteSpace) {
      functionTools.add(AlphaVantageTool());
    }

    return functionTools;
  }

  List<Tool> getToolDeclarations(PreferencesService preferences) {
    final funcTools = initializeFunctionTools(preferences);
    final tools = <Tool>[];
    for (final funcTool in funcTools) {
      if (funcTool.isAvailable(preferences)) {
        tools.add(funcTool.getTool(preferences));
      }
    }

    return tools;
  }

  Tool getFunctionDeclarations(PreferencesService preferences) {
    final funcTools = initializeFunctionTools(preferences);
    final functionDeclarations = <FunctionDeclaration>[];
    for (final funcTool in funcTools) {
      if (funcTool.isAvailable(preferences)) {
        functionDeclarations
            .addAll(funcTool.getFunctionDeclarations(preferences));
      }
    }

    return Tool.functionDeclarations(
      functionDeclarations,
    );
  }

  Future<FunctionResponse?> dispatchFunctionCall(
    FunctionCall call,
    PreferencesService preferences,
  ) async {
    for (final functionTool in functionTools) {
      if (functionTool.canDispatchFunctionCall(call)) {
        final futureResponse = functionTool.dispatchFunctionCall(
          call,
          preferences,
        );

        final functionResponses = await Future.wait([futureResponse]);
        if (functionResponses.isNotEmptyOrNull) {
          return functionResponses[0];
        }
      }
    }

    return FunctionResponse(call.name, {});
  }
}
