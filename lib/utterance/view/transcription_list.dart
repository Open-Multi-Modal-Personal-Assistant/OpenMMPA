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

  Transcriptions.fromJson(Map<String, dynamic> json) {
    if (json['transcripts'] != null) {
      transcriptions.clear();
      final typedTranscripts = json['transcripts'] as List<Map<String, String>>;
      for (final transcriptJson in typedTranscripts) {
        transcriptions.add(Transcription.fromJson(transcriptJson));
      }
    }
  }

  final List<Transcription> transcriptions = [];

  String get merged => transcriptions.map((tr) => tr.transcription).join('. ');
}
