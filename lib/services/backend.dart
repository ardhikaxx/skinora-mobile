import 'package:firebase_core/firebase_core.dart';

/// Central switch that indicates whether the Firebase backend is available.
///
/// All features connect to Firebase Auth + Cloud Firestore.
class Backend {
  Backend._();

  /// True when Firebase has been initialized in this isolate.
  static bool get useFirebase => Firebase.apps.isNotEmpty;

  /// Firebase Auth is only touched when the platform options resolved.
  static bool get useAuth => useFirebase;

  static String describe() =>
      useFirebase ? 'firebase' : 'disconnected';
}
