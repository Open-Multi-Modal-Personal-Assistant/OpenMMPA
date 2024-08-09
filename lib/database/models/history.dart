import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class History {
  History(this.role, this.content, this.locale) {
    dateTime = DateTime.now();
  }

  @Id()
  int id = 0;

  String role; // "system", "user", "image", or function name
  String content;
  String locale;
  String rewrite = '';

  @HnswIndex(dimensions: 768)
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
      case 'image':
        return Icons.image;
      default:
        return Icons.extension;
    }
  }
}
