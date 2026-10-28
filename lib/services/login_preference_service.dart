import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi "Ingat saya" pada halaman login.
///
/// Hanya **email** yang disimpan (password tidak pernah disimpan), sehingga
/// setelah logout kolom email otomatis terisi dengan akun terakhir.
class LoginPreferenceService {
  LoginPreferenceService._();

  static const String _emailKey = 'skinora.remembered_email';
  static const String _enabledKey = 'skinora.remember_me';

  /// Apakah "Ingat saya" aktif. Default aktif agar email akun terakhir
  /// langsung terisi saat pengguna kembali ke halaman login.
  static Future<bool> isRememberEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Email akun terakhir yang diingat, atau '' bila tidak ada / fitur mati.
  static Future<String> rememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    if (!enabled) return '';
    return (prefs.getString(_emailKey) ?? '').trim();
  }

  /// Simpan email untuk login berikutnya (dinormalisasi ke huruf kecil).
  static Future<void> remember(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = email.trim().toLowerCase();
    await prefs.setBool(_enabledKey, true);
    if (normalized.isEmpty) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, normalized);
    }
  }

  /// Aktif/nonaktifkan "Ingat saya" tanpa menghapus email tersimpan.
  static Future<void> setRememberEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Lupakan akun: hapus email dan matikan "Ingat saya".
  static Future<void> forget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    await prefs.remove(_emailKey);
  }
}
