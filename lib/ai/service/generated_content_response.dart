import 'package:google_generative_ai/google_generative_ai.dart';

extension GeneratedContentResponse on GenerateContentResponse {
  String strippedText() {
    if (text == null || text!.isEmpty) {
      return '';
    }

    if (text!.contains('<response>')) {
      final responseBeginIndex = text!.indexOf('<response>');
      if (text!.contains('</response>', responseBeginIndex)) {
        final responseEndIndex = text!.indexOf('</response>');
        return text!
            .substring(
              responseBeginIndex + '<response>'.length,
              responseEndIndex,
            )
            .trim();
      }
    }

    return text!;
  }
}
