import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/dialogs/admin_action_dialogs.dart';
import '../../models/admin_user_model.dart';
import '../../models/satusehat_models.dart';
import '../../models/user_profile.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/satusehat_config.dart';
import '../../services/satusehat_service.dart';

/// Halaman integrasi SATUSEHAT (mode Sandbox / Production) untuk:
/// - Menguji koneksi OAuth2 & Organization ke SATUSEHAT
/// - Memeriksa pasien di SATUSEHAT berdasarkan NIK
/// - Memilih wilayah administratif dari Masterdata SATUSEHAT
/// - Mengirim / mendaftarkan data pasien FHIR R4 (`POST /Patient`)
class SatuSehatPatientSyncPage extends StatefulWidget {
  final UserProfile? userProfile;
  final AdminUserModel? adminUser;
  final bool isSandboxConsole;

  const SatuSehatPatientSyncPage({
    super.key,
    this.userProfile,
    this.adminUser,
    this.isSandboxConsole = false,
  });

  factory SatuSehatPatientSyncPage.forPatient(UserProfile profile) {
    return SatuSehatPatientSyncPage(userProfile: profile);
  }

  factory SatuSehatPatientSyncPage.forAdminUser(AdminUserModel user) {
    return SatuSehatPatientSyncPage(adminUser: user);
  }

  factory SatuSehatPatientSyncPage.sandboxConsole() {
    return const SatuSehatPatientSyncPage(isSandboxConsole: true);
  }

  @override
  State<SatuSehatPatientSyncPage> createState() =>
      _SatuSehatPatientSyncPageState();
}

class _SatuSehatPatientSyncPageState extends State<SatuSehatPatientSyncPage> {
  static const Color primaryMaroon = Color(0xFF8B2B38);
  static const Color darkText = Color(0xFF3F141E);
  static const Color subText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color cardBorder = Color(0xFFEEEEEE);

  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedGender = 'Perempuan';
  String _selectedMaritalCode = 'S';

  String _provinceCode = '';
  String _provinceName = '';
  String _cityCode = '';
  String _cityName = '';
  String _districtCode = '';
  String _districtName = '';
  String _villageCode = '';
  String _villageName = '';

  List<SatuSehatRegionItem> _provinces = const [];
  List<SatuSehatRegionItem> _cities = const [];
  List<SatuSehatRegionItem> _districts = const [];
  List<SatuSehatRegionItem> _villages = const [];

  bool _loadingRegions = false;
  bool _testingConnection = false;
  bool _searchingNik = false;
  bool _syncing = false;
  bool _showPayloadPreview = false;
  bool _showResponseJson = false;

  String _ihsNumber = '';
  String _satuSehatStatus = '';
  String _syncedAtIso = '';
  String _errorMessage = '';

  SatuSehatOrganizationInfo? _orgInfo;
  SatuSehatPatientSyncResult? _lastResult;
  SatuSehatPatientRecord? _foundRecord;

  @override
  void initState() {
    super.initState();
    _seedInitialFields();
    _loadProvinces();
  }

  void _seedInitialFields() {
    final p = widget.userProfile;
    final a = widget.adminUser;

    if (p != null) {
      _nikController.text = p.nik;
      _nameController.text = p.name;
      _phoneController.text = p.phone;
      _emailController.text = p.email;
      _birthDateController.text = p.birthDate;
      _addressController.text = p.address;
      _postalCodeController.text = p.postalCode;
      _selectedGender =
          p.gender.trim().isNotEmpty ? p.gender.trim() : 'Perempuan';
      _selectedMaritalCode = p.maritalStatusCode.trim().isNotEmpty
          ? p.maritalStatusCode.trim()
          : 'S';
      _provinceCode = p.provinceCode;
      _provinceName = p.provinceName;
      _cityCode = p.cityCode;
      _cityName = p.cityName;
      _districtCode = p.districtCode;
      _districtName = p.districtName;
      _villageCode = p.villageCode;
      _villageName = p.villageName;
      _ihsNumber = p.ihsNumber;
      _satuSehatStatus = p.satuSehatStatus;
      _syncedAtIso = p.satuSehatSyncedAt;
    } else if (a != null) {
      _nikController.text = a.nik;
      _nameController.text = a.name;
      _phoneController.text = a.phone;
      _emailController.text = a.email;
      _birthDateController.text = a.birthDate;
      _addressController.text = a.address;
      _postalCodeController.text = a.postalCode;
      _selectedGender =
          a.gender.trim().isNotEmpty ? a.gender.trim() : 'Perempuan';
      _selectedMaritalCode = a.maritalStatusCode.trim().isNotEmpty
          ? a.maritalStatusCode.trim()
          : 'S';
      _provinceCode = a.provinceCode;
      _provinceName = a.provinceName;
      _cityCode = a.cityCode;
      _cityName = a.cityName;
      _districtCode = a.districtCode;
      _districtName = a.districtName;
      _villageCode = a.villageCode;
      _villageName = a.villageName;
      _ihsNumber = a.ihsNumber;
      _satuSehatStatus = a.satuSehatStatus;
      _syncedAtIso = a.satuSehatSyncedAt;
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  SatuSehatPatientInput _currentInput() {
    return SatuSehatPatientInput(
      nik: _nikController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender,
      birthDate: _birthDateController.text.trim(),
      addressLine: _addressController.text.trim(),
      provinceCode: _provinceCode,
      provinceName: _provinceName,
      cityCode: _cityCode,
      cityName: _cityName,
      districtCode: _districtCode,
      districtName: _districtName,
      villageCode: _villageCode,
      villageName: _villageName,
      postalCode: _postalCodeController.text.trim(),
      maritalStatusCode: _selectedMaritalCode,
    );
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingRegions = true);
    try {
      final list = await SatuSehatService.fetchProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = list;
      });
      if (_provinceCode.isNotEmpty) {
        await _loadCities(_provinceCode, preserveSelection: true);
      }
    } catch (_) {
      // Master wilayah tetap bisa diisi via tombol contoh sandbox bila offline.
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadCities(
    String provinceCode, {
    bool preserveSelection = false,
  }) async {
    setState(() => _loadingRegions = true);
    try {
      final list = await SatuSehatService.fetchCities(provinceCode);
      if (!mounted) return;
      setState(() {
        _cities = list;
        if (!preserveSelection) {
          _cityCode = '';
          _cityName = '';
          _districtCode = '';
          _districtName = '';
          _villageCode = '';
          _villageName = '';
          _districts = const [];
          _villages = const [];
        }
      });
      if (preserveSelection && _cityCode.isNotEmpty) {
        await _loadDistricts(_cityCode, preserveSelection: true);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadDistricts(
    String cityCode, {
    bool preserveSelection = false,
  }) async {
    setState(() => _loadingRegions = true);
    try {
      final list = await SatuSehatService.fetchDistricts(cityCode);
      if (!mounted) return;
      setState(() {
        _districts = list;
        if (!preserveSelection) {
          _districtCode = '';
          _districtName = '';
          _villageCode = '';
          _villageName = '';
          _villages = const [];
        }
      });
      if (preserveSelection && _districtCode.isNotEmpty) {
        await _loadVillages(_districtCode, preserveSelection: true);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadVillages(
    String districtCode, {
    bool preserveSelection = false,
  }) async {
    setState(() => _loadingRegions = true);
    try {
      final list = await SatuSehatService.fetchVillages(districtCode);
      if (!mounted) return;
      setState(() {
        _villages = list;
        if (!preserveSelection) {
          _villageCode = '';
          _villageName = '';
        }
      });
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  void _applyJakartaSandboxPreset() {
    setState(() {
      _provinceCode = '31';
      _provinceName = 'DKI Jakarta';
      _cityCode = '3171';
      _cityName = 'Kota Adm. Jakarta Pusat';
      _districtCode = '317101';
      _districtName = 'Gambir';
      _villageCode = '3171011001';
      _villageName = 'Gambir';
      if (_postalCodeController.text.trim().isEmpty) {
        _postalCodeController.text = '10110';
      }
      _errorMessage = '';
    });
  }

  Future<void> _pickBirthDate() async {
    DateTime initial = DateTime(1998, 5, 15);
    final raw = _birthDateController.text.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) initial = parsed;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryMaroon,
            onPrimary: Colors.white,
            onSurface: darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleTestConnection() async {
    setState(() {
      _testingConnection = true;
      _errorMessage = '';
    });
    try {
      final org = await SatuSehatService.verifyConnection();
      if (!mounted) return;
      setState(() => _orgInfo = org);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terhubung ke SATUSEHAT (${org.name})',
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  Future<void> _handleSearchByNik() async {
    final nik = _nikController.text.trim();
    if (!RegExp(r'^\d{16}$').hasMatch(nik)) {
      setState(
        () => _errorMessage = 'Masukkan NIK 16 digit untuk mencari di SATUSEHAT.',
      );
      return;
    }

    setState(() {
      _searchingNik = true;
      _errorMessage = '';
      _foundRecord = null;
    });

    try {
      final record = await SatuSehatService.searchPatientByNik(nik);
      if (!mounted) return;
      setState(() {
        _foundRecord = record;
        if (record != null) {
          _ihsNumber = record.ihsNumber;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            record != null
                ? 'Pasien ditemukan! IHS Number: ${record.ihsNumber}'
                : 'NIK belum terdaftar di SATUSEHAT. Anda bisa kirim data baru.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _searchingNik = false);
    }
  }

  Future<void> _handleSyncPatient() async {
    final input = _currentInput();
    final errors = SatuSehatService.validatePatientInput(input);
    if (errors.isNotEmpty) {
      setState(() => _errorMessage = errors.first);
      return;
    }

    setState(() {
      _syncing = true;
      _errorMessage = '';
    });

    try {
      SatuSehatPatientSyncResult result;
      if (widget.userProfile != null) {
        result = await SatuSehatService.syncAndPersistUserProfile(
          widget.userProfile!,
          inputOverride: input,
        );
        if (Backend.useFirebase && AuthService.uid != null) {
          await ActivityService.log(
            title: 'Sinkronisasi pasien ke SATUSEHAT (${result.ihsNumber})',
            tag: 'Profil',
            actor: input.name,
            actorUid: AuthService.uid!,
          ).catchError((_) {});
        }
      } else if (widget.adminUser != null) {
        result = await SatuSehatService.syncAndPersistAdminUser(
          widget.adminUser!,
          inputOverride: input,
        );
        if (Backend.useFirebase) {
          await ActivityService.log(
            title:
                'Sinkronisasi pasien ${input.name} ke SATUSEHAT (${result.ihsNumber})',
            tag: 'Pengguna',
            actor: 'Admin',
            actorUid: AuthService.uid ?? 'admin',
          ).catchError((_) {});
        }
      } else {
        result = await SatuSehatService.syncPatient(input);
      }

      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _ihsNumber = result.ihsNumber;
        _satuSehatStatus = 'terhubung';
        _syncedAtIso = result.syncedAtIso;
      });

      AdminSuccessDialog.show(
        context,
        title: result.isCreated
            ? 'Pasien Terdaftar di SATUSEHAT'
            : 'Pasien Terhubung ke SATUSEHAT',
        message:
            '${result.message}\n\nEnvironment: ${SatuSehatConfig.current.environmentLabel}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _satuSehatStatus = 'gagal';
      });
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _popWithUpdatedData() {
    if (widget.adminUser != null) {
      final updated = widget.adminUser!.copyWith(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : widget.adminUser!.name,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _selectedGender,
        nik: _nikController.text.trim(),
        ihsNumber: _ihsNumber,
        satuSehatStatus: _satuSehatStatus,
        satuSehatSyncedAt: _syncedAtIso,
        provinceCode: _provinceCode,
        provinceName: _provinceName,
        cityCode: _cityCode,
        cityName: _cityName,
        districtCode: _districtCode,
        districtName: _districtName,
        villageCode: _villageCode,
        villageName: _villageName,
        postalCode: _postalCodeController.text.trim(),
        maritalStatusCode: _selectedMaritalCode,
      );
      Navigator.pop(context, updated);
      return;
    }

    if (widget.userProfile != null) {
      final updated = widget.userProfile!.copyWith(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : widget.userProfile!.name,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _selectedGender,
        nik: _nikController.text.trim(),
        ihsNumber: _ihsNumber,
        satuSehatStatus: _satuSehatStatus,
        satuSehatSyncedAt: _syncedAtIso,
        provinceCode: _provinceCode,
        provinceName: _provinceName,
        cityCode: _cityCode,
        cityName: _cityName,
        districtCode: _districtCode,
        districtName: _districtName,
        villageCode: _villageCode,
        villageName: _villageName,
        postalCode: _postalCodeController.text.trim(),
        maritalStatusCode: _selectedMaritalCode,
      );
      Navigator.pop(context, updated);
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = SatuSehatConfig.current;
    final payloadPreview = const JsonEncoder.withIndent('  ')
        .convert(SatuSehatService.buildFhirPatientPayload(_currentInput()));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithUpdatedData();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFCFD),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 20.0,
                  top: 14.0,
                  bottom: 10.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        color: primaryMaroon,
                        size: 22,
                      ),
                      onPressed: _popWithUpdatedData,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Integrasi SATUSEHAT',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Text(
                        cfg.isSandbox ? 'SANDBOX' : 'PROD',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC2410C),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: const Color(0xFFF0F0F0),
                margin: const EdgeInsets.only(bottom: 14.0),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    _buildConnectionCard(cfg),
                    const SizedBox(height: 14),
                    _buildSyncStatusCard(),
                    const SizedBox(height: 14),
                    if (_errorMessage.isNotEmpty) ...[
                      _buildErrorBanner(_errorMessage),
                      const SizedBox(height: 14),
                    ],
                    _buildPatientFormCard(),
                    const SizedBox(height: 14),
                    _buildPayloadPreviewCard(payloadPreview),
                    if (_lastResult != null) ...[
                      const SizedBox(height: 14),
                      _buildResponseCard(_lastResult!),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _syncing ? null : _handleSyncPatient,
                        icon: _syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                LucideIcons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                        label: Text(
                          _syncing
                              ? 'Mengirim ke SATUSEHAT...'
                              : 'Kirim Pasien ke SATUSEHAT',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard(SatuSehatConfig cfg) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3D8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.server,
                  size: 18,
                  color: primaryMaroon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SATUSEHAT ${cfg.environmentLabel}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Org ID: ${cfg.organizationId}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: subText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _testingConnection ? null : _handleTestConnection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryMaroon,
                  side: const BorderSide(color: primaryMaroon),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: _testingConnection
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Tes Koneksi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
          if (_orgInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                'Koneksi aktif: ${_orgInfo!.name} (Status: ${_orgInfo!.active ? "Aktif" : "Nonaktif"})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    final connected = _ihsNumber.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: connected ? const Color(0xFFBBF7D0) : cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected ? LucideIcons.circleCheck : LucideIcons.userCheck,
            size: 22,
            color: connected ? const Color(0xFF15803D) : subText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? 'Terhubung ke SATUSEHAT'
                      : 'Pasien Belum Tersinkronisasi',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: connected ? const Color(0xFF166534) : darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'IHS Number: $_ihsNumber'
                      : (_satuSehatStatus == 'gagal'
                          ? 'Percobaan terakhir gagal — perbaiki data lalu kirim ulang.'
                          : 'Lengkapi NIK & wilayah lalu kirim untuk mendapatkan IHS Number.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: connected ? const Color(0xFF15803D) : subText,
                  ),
                ),
                if (_foundRecord != null && _foundRecord!.name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Nama di SATUSEHAT: ${_foundRecord!.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (connected)
            IconButton(
              tooltip: 'Salin IHS Number',
              icon: const Icon(
                LucideIcons.copy,
                size: 18,
                color: Color(0xFF15803D),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _ihsNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('IHS Number $_ihsNumber disalin.')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF991B1B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientFormCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATA PASIEN FHIR R4',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),

          // NIK + Cek Button
          _fieldLabel('NIK (16 DIGIT) *'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _textBox(
                  controller: _nikController,
                  hint: '3171012345678902',
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _searchingNik ? null : _handleSearchByNik,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryMaroon,
                    side: const BorderSide(color: primaryMaroon),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _searchingNik
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Cek NIK',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _fieldLabel('NAMA LENGKAP *'),
          const SizedBox(height: 6),
          _textBox(controller: _nameController, hint: 'Nama sesuai KTP'),
          const SizedBox(height: 14),

          _fieldLabel('NOMOR TELEPON *'),
          const SizedBox(height: 6),
          _textBox(
            controller: _phoneController,
            hint: '081234567890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),

          _fieldLabel('EMAIL (OPSIONAL)'),
          const SizedBox(height: 6),
          _textBox(
            controller: _emailController,
            hint: 'pasien@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('TANGGAL LAHIR *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickBirthDate,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _birthDateController,
                                  readOnly: true,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: darkText,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'YYYY-MM-DD',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: subText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('JENIS KELAMIN *'),
                    const SizedBox(height: 6),
                    _dropdownBox<String>(
                      value: ['Perempuan', 'Laki-laki']
                              .contains(_selectedGender)
                          ? _selectedGender
                          : 'Perempuan',
                      items: const ['Perempuan', 'Laki-laki']
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedGender = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _fieldLabel('STATUS PERNIKAHAN'),
          const SizedBox(height: 6),
          _dropdownBox<String>(
            value: SatuSehatMaritalStatus.byCode(_selectedMaritalCode).code,
            items: SatuSehatMaritalStatus.options
                .map(
                  (m) => DropdownMenuItem(
                    value: m.code,
                    child: Text(m.labelId),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedMaritalCode = v);
            },
          ),
          const SizedBox(height: 14),

          _fieldLabel('ALAMAT LENGKAP *'),
          const SizedBox(height: 6),
          _textBox(
            controller: _addressController,
            hint: 'Jl. Merdeka No. 10',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'KODE WILAYAH KEMENDAGRI *',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_loadingRegions)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(
                LucideIcons.mapPin,
                size: 14,
                color: primaryMaroon,
              ),
              label: const Text(
                'Isi Wilayah Contoh Jakarta (Sandbox)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: primaryMaroon,
                ),
              ),
              backgroundColor: const Color(0xFFFFF5F5),
              side: const BorderSide(color: Color(0xFFFECDD3)),
              onPressed: _applyJakartaSandboxPreset,
            ),
          ),
          const SizedBox(height: 10),

          _regionDropdown(
            label: 'Provinsi',
            selectedCode: _provinceCode,
            selectedName: _provinceName,
            items: _provinces,
            onSelected: (item) {
              setState(() {
                _provinceCode = item.code;
                _provinceName = item.name;
              });
              _loadCities(item.code);
            },
          ),
          const SizedBox(height: 10),
          _regionDropdown(
            label: 'Kota / Kabupaten',
            selectedCode: _cityCode,
            selectedName: _cityName,
            items: _cities,
            onSelected: (item) {
              setState(() {
                _cityCode = item.code;
                _cityName = item.name;
              });
              _loadDistricts(item.code);
            },
          ),
          const SizedBox(height: 10),
          _regionDropdown(
            label: 'Kecamatan',
            selectedCode: _districtCode,
            selectedName: _districtName,
            items: _districts,
            onSelected: (item) {
              setState(() {
                _districtCode = item.code;
                _districtName = item.name;
              });
              _loadVillages(item.code);
            },
          ),
          const SizedBox(height: 10),
          _regionDropdown(
            label: 'Kelurahan / Desa',
            selectedCode: _villageCode,
            selectedName: _villageName,
            items: _villages,
            onSelected: (item) {
              setState(() {
                _villageCode = item.code;
                _villageName = item.name;
              });
            },
          ),
          const SizedBox(height: 14),

          _fieldLabel('KODE POS (OPSIONAL)'),
          const SizedBox(height: 6),
          _textBox(
            controller: _postalCodeController,
            hint: '10110',
            keyboardType: TextInputType.number,
            maxLength: 5,
          ),
        ],
      ),
    );
  }

  Widget _regionDropdown({
    required String label,
    required String selectedCode,
    required String selectedName,
    required List<SatuSehatRegionItem> items,
    required ValueChanged<SatuSehatRegionItem> onSelected,
  }) {
    final effectiveItems = List<SatuSehatRegionItem>.from(items);
    if (selectedCode.isNotEmpty &&
        !effectiveItems.any((e) => e.code == selectedCode)) {
      effectiveItems.insert(
        0,
        SatuSehatRegionItem(
          code: selectedCode,
          parentCode: '',
          bpsCode: selectedCode,
          name: selectedName.isNotEmpty ? selectedName : selectedCode,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label.toUpperCase()),
        const SizedBox(height: 4),
        _dropdownBox<String>(
          value: selectedCode.isNotEmpty ? selectedCode : null,
          hint: effectiveItems.isEmpty
              ? 'Pilih / muat $label'
              : 'Pilih $label',
          items: effectiveItems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.code,
                  child: Text(
                    '${item.name} (${item.code})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (code) {
            if (code == null) return;
            final match = effectiveItems.firstWhere(
              (e) => e.code == code,
              orElse: () => SatuSehatRegionItem(
                code: code,
                parentCode: '',
                bpsCode: code,
                name: code,
              ),
            );
            onSelected(match);
          },
        ),
      ],
    );
  }

  Widget _buildPayloadPreviewCard(String jsonText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                setState(() => _showPayloadPreview = !_showPayloadPreview),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(LucideIcons.code, size: 18, color: primaryMaroon),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Preview Payload FHIR R4 Patient',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                  ),
                  Icon(
                    _showPayloadPreview
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: subText,
                  ),
                ],
              ),
            ),
          ),
          if (_showPayloadPreview)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                jsonText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFFE2E8F0),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(SatuSehatPatientSyncResult result) {
    final formatted =
        const JsonEncoder.withIndent('  ').convert(result.responseJson);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _showResponseJson = !_showResponseJson),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.fileJson,
                    size: 18,
                    color: Color(0xFF15803D),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respon SATUSEHAT (${result.action.toUpperCase()})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'IHS: ${result.ihsNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showResponseJson
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: subText,
                  ),
                ],
              ),
            ),
          ),
          if (_showResponseJson)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                formatted,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFFBBF7D0),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: Color(0xFF555555),
      ),
    );
  }

  Widget _textBox({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: darkText,
        ),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _dropdownBox<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              : null,
          icon: const Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: subText,
          ),
          style: const TextStyle(
            fontSize: 13.5,
            color: darkText,
            fontWeight: FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
