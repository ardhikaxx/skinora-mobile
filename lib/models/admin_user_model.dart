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

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.gender,
    this.status = UserStatus.aktif,
  });

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? birthDate,
    String? gender,
    UserStatus? status,
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
    );
  }
}
