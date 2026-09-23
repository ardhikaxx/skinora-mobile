import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'backend.dart';
import 'user_service.dart';

/// Firebase Authentication (Email & Password) sebagai satu-satunya
/// sistem autentikasi. UID Auth adalah identitas utama user.
class AuthService {
  AuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static bool get isSignedIn => Backend.useAuth && _auth.currentUser != null;

  static String? get uid => Backend.useAuth ? _auth.currentUser?.uid : null;

  static User? get currentUser => Backend.useAuth ? _auth.currentUser : null;

  /// Session persistence + auth state source of truth.
  static Stream<User?> get authStateChanges => Backend.useAuth
      ? _auth.authStateChanges()
      : const Stream<User?>.empty();

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Membuat akun Auth + dokumen profile.
  /// - Register hanya untuk pengguna (dan dokter yang di-provision admin).
  /// - Provision role `admin` → ditolak (admin sudah terdaftar pertama).
  /// - Provision role `dokter` → diwariskan saat email cocok.
  /// - Selain itu role = 'pengguna'.
  ///
  /// Catatan: cek provision dilakukan SETELAH Auth account dibuat
  /// (rules hanya mengizinkan read provision bila sudah signed in).
  static Future<UserCredential> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    try {
      final blockReason = await UserService.registerBlockReason(email);
      if (blockReason != null) {
        await credential.user?.delete();
        throw FirebaseAuthException(
          code: 'register-not-allowed',
          message: blockReason,
        );
      }
      await UserService.createProfileOnRegister(
        uid: uid,
        email: email.trim(),
        name: name,
        phone: phone,
      );
    } catch (_) {
      // Bersihkan Auth account bila profile gagal dibuat (tidak orphan).
      try {
        await credential.user?.delete();
      } catch (_) {
        // ignore: best-effort cleanup
      }
      rethrow;
    }
    return credential;
  }

  static Future<void> signOut() async {
    if (!Backend.useAuth) return;
    await _auth.signOut();
  }

  static Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<UserProfile?> loadProfile() async {
    final u = uid;
    if (u == null) return null;
    return UserService.loadByUid(u);
  }

  /// Pesan error Indonesia memakai slot `_errorMessage` login / snackbar
  /// register yang sudah ada di UI.
  static String describeAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun Anda telah dinonaktifkan.';
        case 'user-not-found':
        case 'no-user-record':
          return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-argument':
          return 'Email atau password salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan gunakan menu Masuk.';
        case 'weak-password':
          return 'Password minimal 6 karakter.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Koneksi gagal. Periksa jaringan Anda.';
        case 'operation-not-allowed':
          return 'Metode Email/Password belum diaktifkan di Firebase.';
        case 'register-not-allowed':
          return error.message ?? 'Pendaftaran tidak diizinkan untuk email ini.';
        case 'configuration-not-found':
          return 'Konfigurasi Firebase belum lengkap.';
        default:
          return 'Terjadi kesalahan. Silakan coba lagi.';
      }
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
