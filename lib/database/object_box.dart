import 'package:inspector_gadget/objectbox.g.dart'; // created by `flutter pub run build_runner build`
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ObjectBox {
  ObjectBox._create(this.store) {
    // Any additional setup code, e.g. build queries.
  }

  late final Store store;

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // openStore() is defined in the generated objectbox.g.dart
    final store = await openStore(directory: p.join(docsDir.path, 'obx'));
    return ObjectBox._create(store);
  }
}
