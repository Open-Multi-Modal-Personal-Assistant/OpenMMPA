import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:inspector_gadget/preferences/service/preferences.dart';

abstract class FunctionTool {
  bool isAvailable(PreferencesService preferences);

  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesService preferences,
  );

  Tool getTool(PreferencesService preferences);

  bool canDispatchFunctionCall(FunctionCall call);

  Future<FunctionResponse?> dispatchFunctionCall(
    FunctionCall call,
    PreferencesService preferences,
  );
}
