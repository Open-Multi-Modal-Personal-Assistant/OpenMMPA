import 'dart:async';

import 'package:inspector_gadget/common/state_logging_mixin.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/models/personalization.dart';
import 'package:inspector_gadget/database/object_box.dart';
import 'package:inspector_gadget/objectbox.g.dart'; // created by `flutter pub run build_runner build`

class DatabaseService with StateLoggingMixin {
  ObjectBox? objectBox;
  bool initialized = false;

  Future<DatabaseService> init() async {
    if (initialized) {
      logEvent('ObjectBox already initialized');
      return this;
    }

    initialized = true;
    objectBox = await ObjectBox.create();

    return this;
  }

  Future<List<Personalization>> personalizationPaged(
    int offset,
    int limit,
  ) async {
    if (objectBox == null) {
      return [];
    }

    final box = objectBox!.store.box<Personalization>();
    final query = box
        .query(Personalization_.id.notNull())
        .order(Personalization_.id)
        .build()
      ..offset = offset
      ..limit = limit;
    final personalization = query.find();
    query.close();
    return personalization;
  }

  void deletePersonalization(int id) {
    objectBox?.store.box<Personalization>().remove(id);
  }

  int addUpdatePersonalization(Personalization personalization) {
    return objectBox?.store.box<Personalization>().put(personalization) ?? -1;
  }

  Future<List<ObjectWithScore<Personalization>>> getNearestPersonalization(
    List<double> embedding, [
    int bigLimit = 20,
    int littleLimit = 5,
  ]) async {
    if (objectBox == null || embedding.isEmpty) {
      return [];
    }

    final box = objectBox!.store.box<Personalization>();
    final query = box
        .query(
          Personalization_.embedding.nearestNeighborsF32(embedding, bigLimit),
        )
        .build()
      ..limit = littleLimit;

    // TODO(MrCsabaToth): Weaviate style auto-cut and also slash too low scores
    return query.findWithScores();
  }

  Future<List<History>> historyPaged(int offset, int limit) async {
    if (objectBox == null) {
      return [];
    }

    final box = objectBox!.store.box<History>();
    final query = box
        .query(History_.id.notNull())
        .order(History_.id, flags: Order.descending)
        .build()
      ..offset = offset
      ..limit = limit;
    final history = query.find();
    query.close();
    return history;
  }

  int addUpdateHistory(History history) {
    return objectBox?.store.box<History>().put(history) ?? -1;
  }

  Future<List<History>> limitedHistory(int limit, DateTime watermark) async {
    if (objectBox == null) {
      return [];
    }

    final box = objectBox!.store.box<History>();
    final query = box
        .query(History_.dateTime.lessThanDate(watermark))
        .order(History_.id, flags: Order.descending)
        .build()
      ..limit = limit;
    final history = query.find();
    query.close();
    return history;
  }

  int clearHistory() {
    final box = objectBox!.store.box<History>();
    return box.removeAll();
  }

  Future<List<ObjectWithScore<History>>> getNearestHistory(
    List<double> embedding,
    DateTime watermark, [
    int bigLimit = 20,
    int littleLimit = 5,
  ]) async {
    if (objectBox == null || embedding.isEmpty) {
      return [];
    }

    final box = objectBox!.store.box<History>();
    final query = box
        .query(
          History_.dateTime
              .lessThanDate(watermark)
              .and(History_.embedding.nearestNeighborsF32(embedding, bigLimit)),
        )
        .build()
      ..limit = littleLimit;

    // TODO(MrCsabaToth): Weaviate style auto-cut and also slash too low scores
    return query.findWithScores();
  }
}
