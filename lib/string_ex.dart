import 'package:strings/strings.dart';

extension StringEx on String {
  bool localeMatch(String other) {
    return isNotEmpty &&
        left(2).toLowerCase() == other.left(2).toLowerCase() &&
        right(2).toUpperCase() == other.right(2).toUpperCase();
  }
}
