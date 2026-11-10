import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Centralized service to coordinate Firebase initialization and configuration.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  /// Whether Firebase has been successfully initialized in this session.
  static bool get isInitialized => _initialized;

  /// Initializes the default Firebase application instance.
  /// Safely catches platform-specific missing config errors for robust local preview.
  static Future<void> initialize() async {
    if (_initialized) return;

    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      debugPrint('[FirebaseService] Firebase already initialized.');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e, stack) {
      if (e.code == 'duplicate-app') {
        _initialized = true;
        debugPrint(
            '[FirebaseService] Default Firebase app was initialized by the platform.');
        return;
      }
      debugPrint('[FirebaseService] Error during Firebase initialization: $e');
      debugPrint(stack.toString());
      Error.throwWithStackTrace(e, stack);
    } catch (e, stack) {
      debugPrint('[FirebaseService] Error during Firebase initialization: $e');
      debugPrint(stack.toString());
      Error.throwWithStackTrace(e, stack);
    }

    _initialized = true;
    debugPrint('[FirebaseService] Firebase initialized successfully.');
  }
}
