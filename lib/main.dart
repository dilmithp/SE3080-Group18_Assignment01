import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/app.dart';
import 'package:elderly_companion/core/config/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase isn't configured until `flutterfire configure` has been run
  // (see firebase_options.dart and README.md). Swallow the failure so the
  // UI skeleton is still runnable before that step — every teammate should
  // be able to `flutter run` on day one, not just whoever sets up Firebase.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase.initializeApp failed — run `flutterfire configure`. $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const ProviderScope(child: App()));
}
