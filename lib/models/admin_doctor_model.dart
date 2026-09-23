enum DoctorStatus {
  semua('Semua'),
  menunggu('Menunggu'),
  terverifikasi('Terverifikasi'),
  ditolak('Ditolak'),
  ditangguhkan('Ditangguhkan');

  final String label;
  const DoctorStatus(this.label);
}

class AdminDoctorModel {
  final String id;
  String name;
  String email;
  String phone;
  String specialization;
  String experience;
  String str;
  String bio;
  DoctorStatus status;

  /// Firestore document id (== Firebase Auth uid when registered).
  final String? fsDocId;

  /// false => document still lives in `provisioned_accounts` (not registered yet).
  final bool registered;

  AdminDoctorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.experience,
    required this.str,
    required this.bio,
    required this.status,
    this.fsDocId,
    this.registered = true,
  });

  String get backendId => fsDocId ?? id;

  AdminDoctorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? specialization,
    String? experience,
    String? str,
    String? bio,
    DoctorStatus? status,
    String? fsDocId,
    bool? registered,
  }) {
    return AdminDoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      str: str ?? this.str,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      fsDocId: fsDocId ?? this.fsDocId,
      registered: registered ?? this.registered,
    );
  }
}
