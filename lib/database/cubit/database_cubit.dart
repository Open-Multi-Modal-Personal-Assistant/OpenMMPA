import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:inspector_gadget/database/models/history.dart';
import 'package:inspector_gadget/database/models/personalization.dart';
import 'package:inspector_gadget/database/object_box.dart';
import 'package:inspector_gadget/objectbox.g.dart'; // created by `flutter pub run build_runner build`
import 'package:inspector_gadget/state_logging_mixin.dart';

class DatabaseCubit extends Cubit<ObjectBox?> with StateLoggingMixin {
  DatabaseCubit() : super(null);

  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) {
      logEvent('ObjectBox already initialized');
      return;
    }

    initialized = true;
    final objectBox = await ObjectBox.create();

    emit(objectBox);
  }

  Future<List<Personalization>> personalizationPaged(
    int offset,
    int limit,
  ) async {
    if (state == null) {
      return [];
    }

    final box = state!.store.box<Personalization>();
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
    state?.store.box<Personalization>().remove(id);
  }

  int addUpdatePersonalization(Personalization personalization) {
    return state?.store.box<Personalization>().put(personalization) ?? -1;
  }

  Future<List<History>> historyPaged(int offset, int limit) async {
    if (state == null) {
      return [];
    }

    final box = state!.store.box<History>();
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

  int addUpdateHistory(Personalization personalization) {
    return state?.store.box<Personalization>().put(personalization) ?? -1;
  }

  Future<List<History>> limitedHistory() async {
    if (state == null) {
      return [];
    }

    final box = state!.store.box<History>();
    final query = box
        .query(History_.id.notNull())
        .order(History_.id, flags: Order.descending)
        .build()
      ..limit = 100;
    final history = query.find();
    query.close();
    return history;
  }
}
