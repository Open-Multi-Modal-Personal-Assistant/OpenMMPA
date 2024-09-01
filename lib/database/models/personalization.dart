import 'package:inspector_gadget/common/constants.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Personalization {
  Personalization(this.content, this.locale) {
    dateTime = DateTime.now();
  }

  @Id()
  int id = 0;

  String content;
  String locale;

  @HnswIndex(dimensions: embeddingDimensionality)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  @Property(type: PropertyType.date) // Store as int in milliseconds
  late DateTime dateTime;
}
