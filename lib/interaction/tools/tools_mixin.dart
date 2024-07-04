import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/interaction/tools/alpha_vantage_tool.dart';
import 'package:inspector_gadget/interaction/tools/exchange_tool.dart';
import 'package:inspector_gadget/interaction/tools/function_tool.dart';
import 'package:inspector_gadget/interaction/tools/local_tool.dart';
import 'package:inspector_gadget/interaction/tools/lyrics_tool.dart';
import 'package:inspector_gadget/interaction/tools/sun_time_tool.dart';
import 'package:inspector_gadget/interaction/tools/weather_tool.dart';
import 'package:inspector_gadget/interaction/tools/web_research_tool.dart';
import 'package:inspector_gadget/interaction/tools/web_search_tool.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

mixin ToolsMixin {
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co';
  static const String alphaVantagePath = '/query';

  List<FunctionTool> functionTools = [];

  List<FunctionTool> initializeFunctionTools(PreferencesState? preferences) {
    if (functionTools.isNotEmpty) {
      return functionTools;
    }

    functionTools.addAll([
      AlphaVantageTool(),
      ExchangeTool(),
      LocalTool(),
      LyricsTool(),
      SunTimeTool(),
      WebSearchTool(),
      WebResearchTool(),
      WeatherTool(),
    ]);

    if (!(preferences?.alphaVantageAccessKey.isNullOrWhiteSpace ?? false)) {
      functionTools.add(AlphaVantageTool());
    }

    return functionTools;
  }

  List<Tool> getToolDeclarations(PreferencesState? preferences) {
    final funcTools = initializeFunctionTools(preferences);
    final tools = <Tool>[];
    for (final funcTool in funcTools) {
      if (funcTool.isAvailable(preferences)) {
        tools.add(funcTool.getTool(preferences));
      }
    }

    return tools;
  }

  Future<FunctionResponse?> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  ) async {
    for (final functionTool in functionTools) {
      if (functionTool.canDispatchFunctionCall(call)) {
        final futureResponse = functionTool.dispatchFunctionCall(
          call,
          location,
          hr,
          preferences,
        );

        final functionResponses = await Future.wait([futureResponse]);
        if (functionResponses.isNotEmptyOrNull) {
          return functionResponses[0];
        }
      }
    }

    return FunctionResponse(call.name, null);
  }
}
