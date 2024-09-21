import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inspector_gadget/firebase_options.dart';

mixin FirebaseMixin {
  static Future<void> initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        log('Signed in anonymously with user ID: ${user.uid}');
      } else {
        log('Error signing in anonymously: $userCredential');
      }
    } on FirebaseAuthException catch (e) {
      log('Error signing in anonymously: ${e.message}');
    }
  }
}
