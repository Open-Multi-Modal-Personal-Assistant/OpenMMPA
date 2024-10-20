import 'package:flutter/material.dart';
import 'package:inspector_gadget/common/constants.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class History {
  History(
    this.role,
    this.mode,
    this.content,
    this.locale, [
    this.rewrite = '',
    this.embedding,
    this.mediumPath = '',
    this.mimeType = '',
    this.mediumEmbedding,
  ]) {
    dateTime = DateTime.now();
  }

  @Id()
  int id = 0;

  // 'system', 'user', 'model', mime type (for media), or function name
  String role;
  // 'text_chat', 'media_chat', 'translate', 'image_gen', 'image_edit',
  // 'shazam', 'sound_gen', 'attachment', 'function_call'
  String mode;
  String content;
  String locale;
  String rewrite = '';

  @HnswIndex(dimensions: embeddingDimensionality)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  String mediumPath = '';
  String mimeType = '';

  @HnswIndex(dimensions: embeddingDimensionality)
  @Property(type: PropertyType.floatVector)
  List<double>? mediumEmbedding;

  @Property(type: PropertyType.date) // Store as int in milliseconds
  late DateTime dateTime;

  IconData getIcon() {
    return switch (role) {
      'system' => Icons.computer,
      'user' => Icons.account_circle,
      'model' => Icons.reply,
      'image' => Icons.image,
      _ => Icons.extension,
    };
  }
}
