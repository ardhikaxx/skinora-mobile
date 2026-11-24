/// Profile ringkas yang dipakai service layer (Auth + Firestore).
class UserProfile {
  final String uid; // Firebase Auth uid ('' untuk provision yang belum daftar)
  final String docId; // id dokumen Firestore
  final bool registered; // false => masih di provisioned_accounts
  String name;
  String email;
  String phone;
  String address;
  String birthDate;
  String gender;
  String role; // pengguna | dokter | admin
  String status;

  // dokter
  String specialization;
  String experience;
  String str;
  String bio;
  bool isAvailable;

  // settings
  bool notificationsEnabled;
  String morningReminder;
  String eveningReminder;

  UserProfile({
    this.uid = '',
    required this.docId,
    this.registered = true,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.birthDate = '',
    this.gender = '',
    this.role = 'pengguna',
    this.status = 'aktif',
    this.specialization = '',
    this.experience = '',
    this.str = '',
    this.bio = '',
    this.isAvailable = true,
    this.notificationsEnabled = true,
    this.morningReminder = '',
    this.eveningReminder = '',
  });

  bool get canLogin {
    final s = status.trim().toLowerCase();
    if (s == 'ditangguhkan') return false;
    if (role == 'dokter') {
      // Dokter hanya dapat login jika sudah diverifikasi oleh admin ('terverifikasi' atau 'aktif').
      // Dokter dengan status 'menunggu' atau 'ditolak' TIDAK BISA login.
      return s == 'terverifikasi' || s == 'aktif';
    }
    return true;
  }

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Memeriksa apakah data diri pasien sudah benar-benar lengkap
  /// (nama, telepon, tanggal lahir, jenis kelamin, dan alamat).
  bool get isPatientProfileComplete {
    return name.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        birthDate.trim().isNotEmpty &&
        gender.trim().isNotEmpty &&
        address.trim().isNotEmpty;
  }

  UserProfile copyWith({
    String? uid,
    String? docId,
    bool? registered,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? birthDate,
    String? gender,
    String? role,
    String? status,
    String? specialization,
    String? experience,
    String? str,
    String? bio,
    bool? isAvailable,
    bool? notificationsEnabled,
    String? morningReminder,
    String? eveningReminder,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      docId: docId ?? this.docId,
      registered: registered ?? this.registered,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      status: status ?? this.status,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      str: str ?? this.str,
      bio: bio ?? this.bio,
      isAvailable: isAvailable ?? this.isAvailable,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      morningReminder: morningReminder ?? this.morningReminder,
      eveningReminder: eveningReminder ?? this.eveningReminder,
    );
  }
}
