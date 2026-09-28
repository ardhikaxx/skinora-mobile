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

  /// Ruang yang sedang terbuka di UI (biasanya 1; bisa >1 saat deep-link
  /// notifikasi menumpuk halaman ruang).
  static final List<String> _openRooms = <String>[];

  /// ID konsultasi yang paling terakhir dibuka, atau null bila tidak ada ruang.
  static String? get consultationId =>
      _openRooms.isEmpty ? null : _openRooms.last;

  static void open(String? consultationId) {
    if (consultationId == null || consultationId.isEmpty) return;
    _openRooms.remove(consultationId);
    _openRooms.add(consultationId);
  }

  static void close(String? consultationId) {
    if (consultationId == null || consultationId.isEmpty) {
      _openRooms.clear();
      return;
    }
    _openRooms.remove(consultationId);
  }

  static void clear() => _openRooms.clear();

  /// `true` bila [incomingConsultationId] adalah salah satu ruang yang aktif.
  static bool isActiveRoom(String? incomingConsultationId) {
    if (incomingConsultationId == null || incomingConsultationId.isEmpty) {
      return false;
    }
    return _openRooms.contains(incomingConsultationId);
  }
}
