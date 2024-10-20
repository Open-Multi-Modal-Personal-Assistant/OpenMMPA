import 'package:inspector_gadget/common/constants.dart';

class Embeddings {
  Embeddings();

  Embeddings.fromJson(Map<String, Object?> embeddingMap) {
    textEmbeddings.clear();
    if (embeddingMap.containsKey('text') && embeddingMap['text'] != null) {
      final embeddingsList = embeddingMap['text']! as List<Object?>;
      for (final embeddings in embeddingsList.nonNulls) {
        final embedding = (embeddings as List<Object?>).nonNulls;
        if (embedding.isNotEmpty) {
          textEmbeddings
              .add(dimensionalityReduction(embedding as List<double>));
        }
      }
    }

    imageEmbeddings.clear();
    if (embeddingMap.containsKey('image') && embeddingMap['image'] != null) {
      final embedding = (embeddingMap['image']! as List<Object?>).nonNulls;
      if (embedding.isNotEmpty) {
        imageEmbeddings
            .addAll(dimensionalityReduction(embedding as List<double>));
      }
    }

    videoEmbeddings.clear();
    if (embeddingMap.containsKey('video') && embeddingMap['video'] != null) {
      final embeddingsList = embeddingMap['video']! as List<Object?>;
      for (final embeddings in embeddingsList.nonNulls) {
        final embedding = (embeddings as List<Object?>).nonNulls;
        if (embedding.isNotEmpty) {
          videoEmbeddings
              .add(dimensionalityReduction(embedding as List<double>));
        }
      }
    }
  }

  final List<List<double>> textEmbeddings = [];
  final List<double> imageEmbeddings = [];
  final List<List<double>> videoEmbeddings = [];

  List<double> get textEmbedding =>
      textEmbeddings.isEmpty ? [] : textEmbeddings.first;
  List<double> get imageEmbedding =>
      imageEmbeddings.isEmpty ? [] : imageEmbeddings;

  List<double> dimensionalityReduction(List<double> vector) {
    // Reduction by addition of values
    final foldedVector =
        vector.take(embeddingDimensionality).toList(growable: false);
    if (vector.length > embeddingDimensionality) {
      for (var i = 0, j = embeddingDimensionality;
          j < vector.length;
          i++, j++) {
        foldedVector[i % embeddingDimensionality] += vector[j];
      }
    }

    return foldedVector;
  }
}
