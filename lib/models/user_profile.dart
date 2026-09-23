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

  bool get canLogin =>
      status != 'ditangguhkan' && !(role == 'dokter' && status == 'ditolak');

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
