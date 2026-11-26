import 'admin_user_model.dart';
import 'user_profile.dart';

/// Item wilayah administratif dari API Masterdata SATUSEHAT.
class SatuSehatRegionItem {
  final String code;
  final String parentCode;
  final String bpsCode;
  final String name;

  const SatuSehatRegionItem({
    required this.code,
    required this.parentCode,
    required this.bpsCode,
    required this.name,
  });

  factory SatuSehatRegionItem.fromJson(Map<String, dynamic> json) {
    return SatuSehatRegionItem(
      code: (json['code'] as String?)?.trim() ?? '',
      parentCode: (json['parent_code'] as String?)?.trim() ?? '',
      bpsCode: (json['bps_code'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
    );
  }
}

/// Informasi Organization yang terdaftar di SATUSEHAT.
class SatuSehatOrganizationInfo {
  final String id;
  final String name;
  final bool active;
  final String phone;
  final String email;

  const SatuSehatOrganizationInfo({
    required this.id,
    required this.name,
    required this.active,
    this.phone = '',
    this.email = '',
  });
}

/// Opsi status pernikahan standar HL7 v3-MaritalStatus untuk FHIR Patient.
class SatuSehatMaritalStatus {
  final String code;
  final String display;
  final String labelId;

  const SatuSehatMaritalStatus({
    required this.code,
    required this.display,
    required this.labelId,
  });

  static const List<SatuSehatMaritalStatus> options = [
    SatuSehatMaritalStatus(
      code: 'S',
      display: 'Never Married',
      labelId: 'Belum Menikah',
    ),
    SatuSehatMaritalStatus(
      code: 'M',
      display: 'Married',
      labelId: 'Menikah',
    ),
    SatuSehatMaritalStatus(
      code: 'D',
      display: 'Divorced',
      labelId: 'Cerai Hidup',
    ),
    SatuSehatMaritalStatus(
      code: 'W',
      display: 'Widowed',
      labelId: 'Cerai Mati',
    ),
  ];

  static SatuSehatMaritalStatus byCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final item in options) {
      if (item.code == normalized) return item;
    }
    return options.first;
  }
}

/// Data input pasien Skinora yang akan dikirim/dicocokkan ke SATUSEHAT.
class SatuSehatPatientInput {
  final String nik;
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String birthDate;
  final String addressLine;
  final String provinceCode;
  final String provinceName;
  final String cityCode;
  final String cityName;
  final String districtCode;
  final String districtName;
  final String villageCode;
  final String villageName;
  final String postalCode;
  final String maritalStatusCode;

  const SatuSehatPatientInput({
    required this.nik,
    required this.name,
    required this.phone,
    this.email = '',
    required this.gender,
    required this.birthDate,
    required this.addressLine,
    required this.provinceCode,
    this.provinceName = '',
    required this.cityCode,
    this.cityName = '',
    required this.districtCode,
    this.districtName = '',
    required this.villageCode,
    this.villageName = '',
    this.postalCode = '',
    this.maritalStatusCode = 'S',
  });

  factory SatuSehatPatientInput.fromUserProfile(UserProfile profile) {
    return SatuSehatPatientInput(
      nik: profile.nik.trim(),
      name: profile.name.trim(),
      phone: profile.phone.trim(),
      email: profile.email.trim(),
      gender: profile.gender.trim(),
      birthDate: profile.birthDate.trim(),
      addressLine: profile.address.trim(),
      provinceCode: profile.provinceCode.trim(),
      provinceName: profile.provinceName.trim(),
      cityCode: profile.cityCode.trim(),
      cityName: profile.cityName.trim(),
      districtCode: profile.districtCode.trim(),
      districtName: profile.districtName.trim(),
      villageCode: profile.villageCode.trim(),
      villageName: profile.villageName.trim(),
      postalCode: profile.postalCode.trim(),
      maritalStatusCode: profile.maritalStatusCode.trim().isNotEmpty
          ? profile.maritalStatusCode.trim()
          : 'S',
    );
  }

  factory SatuSehatPatientInput.fromAdminUser(AdminUserModel user) {
    return SatuSehatPatientInput(
      nik: user.nik.trim(),
      name: user.name.trim(),
      phone: user.phone.trim(),
      email: user.email.trim(),
      gender: user.gender.trim(),
      birthDate: user.birthDate.trim(),
      addressLine: user.address.trim(),
      provinceCode: user.provinceCode.trim(),
      provinceName: user.provinceName.trim(),
      cityCode: user.cityCode.trim(),
      cityName: user.cityName.trim(),
      districtCode: user.districtCode.trim(),
      districtName: user.districtName.trim(),
      villageCode: user.villageCode.trim(),
      villageName: user.villageName.trim(),
      postalCode: user.postalCode.trim(),
      maritalStatusCode: user.maritalStatusCode.trim().isNotEmpty
          ? user.maritalStatusCode.trim()
          : 'S',
    );
  }
}

/// Ringkasan resource Patient dari respon SATUSEHAT.
class SatuSehatPatientRecord {
  final String ihsNumber;
  final String name;
  final String gender;
  final String birthDate;
  final String nikMasked;
  final bool active;
  final Map<String, dynamic> rawJson;

  const SatuSehatPatientRecord({
    required this.ihsNumber,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.nikMasked,
    required this.active,
    required this.rawJson,
  });
}

/// Hasil pengiriman / sinkronisasi data pasien ke SATUSEHAT.
class SatuSehatPatientSyncResult {
  final bool success;
  final String action; // 'created' | 'matched'
  final String ihsNumber;
  final String message;
  final String syncedAtIso;
  final Map<String, dynamic> requestPayload;
  final Map<String, dynamic> responseJson;

  const SatuSehatPatientSyncResult({
    required this.success,
    required this.action,
    required this.ihsNumber,
    required this.message,
    required this.syncedAtIso,
    required this.requestPayload,
    required this.responseJson,
  });

  bool get isCreated => action == 'created';
  bool get isMatched => action == 'matched';
}

/// Exception terstruktur untuk kegagalan komunikasi / validasi SATUSEHAT.
class SatuSehatException implements Exception {
  final int? statusCode;
  final String message;
  final String rawBody;

  const SatuSehatException(
    this.message, {
    this.statusCode,
    this.rawBody = '',
  });

  @override
  String toString() => statusCode != null
      ? 'SatuSehatException($statusCode): $message'
      : 'SatuSehatException: $message';
}
