import 'package:firebase_core/firebase_core.dart';

/// Central switch that tells every service whether the real Firebase backend
/// is available.
///
/// - When [Firebase] has been initialized (production/runtime via `main()`),
///   every service talks to Firebase Auth + Cloud Firestore.
/// - When it has NOT been initialized (widget tests, tooling), services fall
///   back to the in-memory demo seed so the existing UI keeps working exactly
///   like the original frontend. Writes are then local-only (page state).
class Backend {
  Backend._();

  /// True when Firebase has been initialized in this isolate.
  static bool get useFirebase => Firebase.apps.isNotEmpty;

  /// Firebase Auth is only touched when the platform options resolved.
  static bool get useAuth => useFirebase;

  static String describe() =>
      useFirebase ? 'firebase' : 'demo (firebase not initialized)';
}
