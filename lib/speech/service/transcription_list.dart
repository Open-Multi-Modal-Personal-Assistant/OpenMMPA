import 'package:collection/collection.dart';

class Transcription {
  Transcription(this.transcription, this.language);

  factory Transcription.fromJson(Map<String, String> json) {
    return Transcription(json['transcription'] ?? '', json['language'] ?? '');
  }

  final String transcription;
  final String language;
}

class Transcriptions {
  Transcriptions();

  Transcriptions.fromJson(List<Object?> transcriptList) {
    transcriptions.clear();
    final stringList =
        transcriptList.nonNulls.map((e) => e as String).toList(growable: false);
    for (var i = 0; i < stringList.length; i += 2) {
      final transcript = stringList[i].trim();
      final language = i + 1 < stringList.length ? stringList[i + 1] : '';
      transcriptions.add(Transcription(transcript, language.trim()));
    }
  }

  final List<Transcription> transcriptions = [];

  String get merged => transcriptions.map((tr) => tr.transcription).join('. ');

  String localeMode() {
    final groupedData = groupBy(transcriptions, (tr) => tr.language);
    final reduced = groupedData.map(
      (lang, trs) => MapEntry(
        lang,
        trs.map((tr) => 1).reduce((a, b) => a + b),
      ),
    );

    final mode = reduced.entries.reduce((a, b) {
      final aValue = a.value;
      final bValue = b.value;

      return aValue > bValue ? a : b;
    }).key;

    return mode;
  }
}
