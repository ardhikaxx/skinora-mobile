/// Registry state foreground untuk "percakapan yang sedang dibuka user".
///
/// Tujuan: anti-spam notifikasi. Ketika user berada di ruang konsultasi yang
/// sama dengan incoming message, native notification TIDAK ditampilkan
/// (chat realtime yang menangani feedback), tetapi dokumen notifikasi tetap
/// disimpan sehingga histori tetap lengkap.
///
/// Ini state in-memory ringan — bukan query Firestore tambahan — sehingga
/// tidak ada biaya read per pesan masuk.
class ActiveChatRegistry {
  ActiveChatRegistry._();

  static String? _consultationId;

  /// ID konsultasi yang sedang dibuka user, atau null bila tidak di ruang chat.
  static String? get consultationId => _consultationId;

  static void open(String? consultationId) {
    _consultationId =
        (consultationId == null || consultationId.isEmpty) ? null : consultationId;
  }

  static void close(String? consultationId) {
    if (consultationId == null ||
        consultationId.isEmpty ||
        _consultationId == consultationId) {
      _consultationId = null;
    }
  }

  static void clear() => _consultationId = null;

  /// `true` bila [incomingConsultationId] adalah ruang yang sedang aktif.
  static bool isActiveRoom(String? incomingConsultationId) {
    if (incomingConsultationId == null || incomingConsultationId.isEmpty) {
      return false;
    }
    return _consultationId == incomingConsultationId;
  }
}
