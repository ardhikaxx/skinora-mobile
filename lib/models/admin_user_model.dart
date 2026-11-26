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

  // SATUSEHAT Patient (FHIR R4)
  String nik;
  String ihsNumber;
  String satuSehatStatus;
  String satuSehatSyncedAt;
  String satuSehatLastError;
  String provinceCode;
  String provinceName;
  String cityCode;
  String cityName;
  String districtCode;
  String districtName;
  String villageCode;
  String villageName;
  String postalCode;
  String maritalStatusCode;

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
    this.nik = '',
    this.ihsNumber = '',
    this.satuSehatStatus = '',
    this.satuSehatSyncedAt = '',
    this.satuSehatLastError = '',
    this.provinceCode = '',
    this.provinceName = '',
    this.cityCode = '',
    this.cityName = '',
    this.districtCode = '',
    this.districtName = '',
    this.villageCode = '',
    this.villageName = '',
    this.postalCode = '',
    this.maritalStatusCode = 'S',
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
    String? nik,
    String? ihsNumber,
    String? satuSehatStatus,
    String? satuSehatSyncedAt,
    String? satuSehatLastError,
    String? provinceCode,
    String? provinceName,
    String? cityCode,
    String? cityName,
    String? districtCode,
    String? districtName,
    String? villageCode,
    String? villageName,
    String? postalCode,
    String? maritalStatusCode,
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
      nik: nik ?? this.nik,
      ihsNumber: ihsNumber ?? this.ihsNumber,
      satuSehatStatus: satuSehatStatus ?? this.satuSehatStatus,
      satuSehatSyncedAt: satuSehatSyncedAt ?? this.satuSehatSyncedAt,
      satuSehatLastError: satuSehatLastError ?? this.satuSehatLastError,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      cityCode: cityCode ?? this.cityCode,
      cityName: cityName ?? this.cityName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      villageCode: villageCode ?? this.villageCode,
      villageName: villageName ?? this.villageName,
      postalCode: postalCode ?? this.postalCode,
      maritalStatusCode: maritalStatusCode ?? this.maritalStatusCode,
    );
  }
}
