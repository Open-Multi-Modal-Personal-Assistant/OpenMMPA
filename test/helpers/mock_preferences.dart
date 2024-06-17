import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pref/pref.dart';

abstract class MockWithExpandedToString extends Mock {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return super.toString();
  }
}

class MockPrefService extends MockWithExpandedToString
    implements BasePrefService {}
