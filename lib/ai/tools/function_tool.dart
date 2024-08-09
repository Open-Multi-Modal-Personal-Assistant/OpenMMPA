import 'package:fl_location/fl_location.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:inspector_gadget/preferences/cubit/preferences_state.dart';

abstract class FunctionTool {
  bool isAvailable(PreferencesState? preferences);

  List<FunctionDeclaration> getFunctionDeclarations(
    PreferencesState? preferences,
  );

  Tool getTool(PreferencesState? preferences);

  bool canDispatchFunctionCall(FunctionCall call);

  Future<FunctionResponse?> dispatchFunctionCall(
    FunctionCall call,
    Location? location,
    int hr,
    PreferencesState? preferences,
  );
}
