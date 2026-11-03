import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  /// Membuat akun Auth + dokumen profile.
  /// - Register untuk pengguna, serta dokter dan admin yang di-provision admin.
  /// - Provision role `dokter` / `admin` → diwariskan saat email cocok.
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
    // Email selalu lowercase agar cocok dengan doc ID provision
    // `provisioned_accounts/{token.email}` di Security Rules.
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final uid = credential.user!.uid;
    try {
      final blockReason = await UserService.registerBlockReason(
        email.trim().toLowerCase(),
      );
      if (blockReason != null) {
        await credential.user?.delete();
        throw FirebaseAuthException(
          code: 'register-not-allowed',
          message: blockReason,
        );
      }
      await UserService.createProfileOnRegister(
        uid: uid,
        email: email.trim().toLowerCase(),
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

  /// Pendaftaran mandiri dokter Skinora.
  /// Membuat akun Firebase Auth, lalu menyimpan dokumen `users/{uid}` dengan
  /// role = 'dokter' dan status = 'menunggu'.
  static Future<UserCredential> registerDoctor({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialization,
    required String str,
    required String experience,
    required String address,
    String bio = '',
  }) async {
    if (!Backend.useAuth) {
      throw const FormatException('Firebase Auth belum aktif');
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final uid = credential.user!.uid;
    try {
      final blockReason = await UserService.registerBlockReason(
        email.trim().toLowerCase(),
      );
      if (blockReason != null) {
        await credential.user?.delete();
        throw FirebaseAuthException(
          code: 'register-not-allowed',
          message: blockReason,
        );
      }
      await UserService.createDoctorProfileOnRegister(
        uid: uid,
        email: email.trim().toLowerCase(),
        name: name,
        phone: phone,
        specialization: specialization,
        str: str,
        experience: experience,
        address: address,
        bio: bio,
      );
    } catch (_) {
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

  static Future<void> sendPasswordReset(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!Backend.useAuth) {
      throw const FormatException('Firebase Auth belum aktif.');
    }
    try {
      await _auth.setLanguageCode('id');
    } catch (_) {
      // Best-effort pada platform yang belum mendukung setLanguageCode
    }
    return _auth.sendPasswordResetEmail(email: cleanEmail);
  }

  /// Pesan error khusus reset kata sandi dalam Bahasa Indonesia yang ramah.
  static String describePasswordResetError(Object error) {
    debugPrint('AuthService.describePasswordResetError: ${error.runtimeType} → $error');
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Format alamat email tidak valid.';
        case 'user-not-found':
          return 'Akun dengan email ini tidak ditemukan.';
        case 'user-disabled':
          return 'Akun Anda telah dinonaktifkan oleh administrator.';
        case 'too-many-requests':
          return 'Terlalu banyak permintaan reset kata sandi. Silakan tunggu beberapa saat.';
        case 'network-request-failed':
          return 'Koneksi gagal. Periksa jaringan internet Anda.';
        case 'missing-email':
          return 'Silakan masukkan alamat email Anda.';
        case 'operation-not-allowed':
          return 'Metode reset kata sandi belum diaktifkan di Firebase Console.';
        default:
          debugPrint('Unhandled reset password error code: ${error.code}');
          return error.message ?? 'Gagal mengirim email reset kata sandi.';
      }
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  static Future<UserProfile?> loadProfile() async {
    final u = uid;
    if (u == null) return null;
    return UserService.loadByUid(u);
  }

  /// Pesan error Indonesia memakai slot `_errorMessage` login / snackbar
  /// register yang sudah ada di UI.
  static String describeAuthError(Object error) {
    debugPrint('AuthService.describeAuthError: ${error.runtimeType} → $error');

    // FirebaseAuthException extends FirebaseException, jadi cek spesifik dulu.
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun Anda telah dinonaktifkan.';
        case 'user-not-found':
        case 'no-user-record':
          return 'Akun tidak ditemukan. Silahkan daftar terlebih dahulu.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-argument':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Email atau password salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silahkan gunakan menu Masuk.';
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
        case 'channel-error':
          return 'Koneksi ke server gagal. Periksa jaringan Anda.';
        default:
          debugPrint('Unhandled FirebaseAuthException code: ${error.code}');
          return 'Email atau password salah.';
      }
    }

    // FirebaseException (Firestore, dll) — bukan Auth error.
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Akses ditolak. Hubungi administrator.';
        case 'unavailable':
          return 'Server sedang tidak tersedia. Coba lagi nanti.';
        case 'not-found':
          return 'Data profil tidak ditemukan.';
        case 'network-request-failed':
          return 'Koneksi gagal. Periksa jaringan Anda.';
        default:
          debugPrint('Unhandled FirebaseException code: ${error.code}');
          return 'Terjadi kesalahan koneksi. Silahkan coba lagi.';
      }
    }

    debugPrint('Non-Firebase error: ${error.runtimeType} → $error');
    return 'Terjadi kesalahan. Silahkan coba lagi.';
  }
}
