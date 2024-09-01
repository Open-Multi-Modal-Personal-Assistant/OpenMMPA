import 'package:flutter/material.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class History {
  History(
    this.role,
    this.content,
    this.locale, [
    this.rewrite = '',
    this.embedding,
  ]) {
    dateTime = DateTime.now();
  }

  @Id()
  int id = 0;

  String role; // "system", "user", "model", "image", or function name
  String content;
  String locale;
  String rewrite = '';

  @HnswIndex(dimensions: embeddingDimensionality)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  @Property(type: PropertyType.date) // Store as int in milliseconds
  late DateTime dateTime;

  IconData getIcon() {
    switch (role) {
      case 'system':
        return Icons.computer;
      case 'user':
        return Icons.account_circle;
      case 'model':
        return Icons.reply;
      case 'image':
        return Icons.image;
      default:
        return Icons.extension;
    }
  }
}
