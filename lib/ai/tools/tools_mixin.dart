import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:inspector_gadget/ai/tools/alpha_vantage_tool.dart';
import 'package:inspector_gadget/ai/tools/exchange_tool.dart';
import 'package:inspector_gadget/ai/tools/function_tool.dart';
import 'package:inspector_gadget/ai/tools/local_tool.dart';
import 'package:inspector_gadget/ai/tools/sun_time_tool.dart';
import 'package:inspector_gadget/ai/tools/weather_tool.dart';
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
      LocalTool(),
      WeatherTool(),
      SunTimeTool(),
      // WebSearchTool(),
      WebResearchTool(),
      ExchangeTool(),
    ]);

    // if (!(preferences?.alphaVantageAccessKey.isNullOrWhiteSpace ?? false)) {
    //   functionTools.add(AlphaVantageTool());
    // }

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

    return Tool(
      functionDeclarations: functionDeclarations,
    );
  }

  String getFunctionCallPromptStuffing(PreferencesService preferences) {
    final funcTools = initializeFunctionTools(preferences);
    final buffer = StringBuffer();
    for (final funcTool in funcTools) {
      if (funcTool.isAvailable(preferences)) {
        for (final function in funcTool.getFunctionDeclarations(preferences)) {
          buffer
            ..writeln('  <function>')
            ..writeln('    <name>${function.name}</name>')
            ..writeln('    <description>${function.description}</description>');
          if (function.parameters != null) {
            final par = function.parameters!;
            buffer
              ..writeln('    <schema>')
              ..writeln('      <schemaType>${par.type}</schemaType>');
            if (par.properties != null) {
              buffer.writeln('      <properties>');
              for (final prop in par.properties!.entries) {
                buffer
                  ..writeln('        <property>')
                  ..writeln('          <name>${prop.key}</name>')
                  ..writeln('          <type>${prop.value.type}</type>')
                  ..writeln(
                    '          <description>${prop.value.description}</description>',
                  )
                  ..writeln('        </property>');
              }

              buffer.writeln('      </properties>');
            }

            buffer.writeln('    </schema>');
          }

          buffer.writeln('  </function>');
        }
      }
    }

    return buffer.toString();
  }

  Future<FunctionResponse?> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesService preferences,
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
