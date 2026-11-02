import 'admin_user_model.dart';

/// Model akun admin untuk fitur Manajemen Admin.
class AdminAccountModel {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  String birthDate;
  String gender;
  UserStatus status;

  /// Firestore document id (== Firebase Auth uid saat registered).
  final String? fsDocId;

  /// false => dokumen masih di `provisioned_accounts` (belum registrasi).
  final bool registered;

  final dynamic createdAt;

  AdminAccountModel({
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
    this.createdAt,
  });

  /// Document id yang dipakai oleh Firestore.
  String get backendId => fsDocId ?? id;

  /// Inisial nama untuk avatar (misal: "Admin Skinora" -> "AS").
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  AdminAccountModel copyWith({
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
    dynamic createdAt,
  }) {
    return AdminAccountModel(
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
