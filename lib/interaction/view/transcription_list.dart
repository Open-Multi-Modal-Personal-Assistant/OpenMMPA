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

  Transcriptions.fromJson(List<dynamic> json) {
    transcriptions.clear();
    final stringList = json.map((e) => e as String).toList(growable: false);
    for (var i = 0; i < stringList.length; i += 2) {
      final transcript = stringList[i].trim();
      final language = i + 1 < stringList.length ? stringList[i + 1] : '';
      transcriptions.add(Transcription(transcript, language.trim()));
    }
  }

  final List<Transcription> transcriptions = [];

  // TODO(MrCsabaToth): handle mixed languages
  String get merged => transcriptions.map((tr) => tr.transcription).join('. ');
}
