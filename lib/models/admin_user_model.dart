enum UserStatus {
  aktif('Aktif'),
  ditangguhkan('Ditangguhkan');

  final String label;
  const UserStatus(this.label);
}

class AdminUserModel {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  String birthDate;
  String gender;
  UserStatus status;

  /// Firestore document id (== Firebase Auth uid when registered).
  /// Falls back to [id] when backend is not active.
  final String? fsDocId;

  /// false => document still lives in `provisioned_accounts` (not registered yet).
  final bool registered;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.gender,
    this.status = UserStatus.aktif,
    this.fsDocId,
    this.registered = true,
  });

  /// Document id used by the backend for updates/deletes.
  String get backendId => fsDocId ?? id;

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? birthDate,
    String? gender,
    UserStatus? status,
    String? fsDocId,
    bool? registered,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      fsDocId: fsDocId ?? this.fsDocId,
      registered: registered ?? this.registered,
    );
  }
}
