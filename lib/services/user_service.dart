import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_account_model.dart';
import '../models/admin_doctor_model.dart';
import '../models/admin_user_model.dart';
import '../models/user_profile.dart';
import 'activity_service.dart';
import 'backend.dart';

/// Akses koleksi `users` + `provisioned_accounts`.
///
/// Kebijakan pembuatan akun:
/// - Pengguna mendaftar sendiri → dokumen `users/{uid}` dibuat saat register.
/// - Admin "Tambah Pengguna/Dokter" TIDAK membuat password (password tidak
///   boleh disimpan di Firestore) → menulis `provisioned_accounts`. Orang
///   tersebut mendaftar dengan email sama dan role/profile diwariskan.
class UserService {
  UserService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  static CollectionReference<Map<String, dynamic>> get _provisions =>
      _db.collection('provisioned_accounts');

  static String userStatusLabel(UserStatus s) =>
      s == UserStatus.aktif ? 'aktif' : 'ditangguhkan';

  static UserStatus userStatusFrom(String raw) =>
      raw == 'ditangguhkan' ? UserStatus.ditangguhkan : UserStatus.aktif;

  static String doctorStatusLabel(DoctorStatus s) {
    switch (s) {
      case DoctorStatus.menunggu:
        return 'menunggu';
      case DoctorStatus.terverifikasi:
        return 'terverifikasi';
      case DoctorStatus.ditolak:
        return 'ditolak';
      case DoctorStatus.ditangguhkan:
        return 'ditangguhkan';
      case DoctorStatus.semua:
        return 'terverifikasi';
    }
  }

  static DoctorStatus doctorStatusFrom(String raw) {
    switch (raw) {
      case 'menunggu':
        return DoctorStatus.menunggu;
      case 'ditolak':
        return DoctorStatus.ditolak;
      case 'ditangguhkan':
        return DoctorStatus.ditangguhkan;
      case 'terverifikasi':
      default:
        return DoctorStatus.terverifikasi;
    }
  }

  static UserProfile _profileFromDoc(
    String docId,
    Map<String, dynamic> d, {
    bool registered = true,
  }) {
    final settings = (d['settings'] as Map<String, dynamic>?) ?? const {};
    return UserProfile(
      uid: (d['uid'] as String?) ?? '',
      docId: docId,
      registered: registered,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      birthDate: (d['birthDate'] as String?) ?? '',
      gender: (d['gender'] as String?) ?? '',
      role: (d['role'] as String?) ?? 'pengguna',
      status: (d['status'] as String?) ?? 'aktif',
      specialization: (d['specialization'] as String?) ?? '',
      experience: (d['experience'] as String?) ?? '',
      str: (d['str'] as String?) ?? '',
      bio: (d['bio'] as String?) ?? '',
      isAvailable: (d['isAvailable'] as bool?) ?? true,
      notificationsEnabled: (settings['notificationsEnabled'] as bool?) ?? true,
      morningReminder: (settings['morningReminder'] as String?) ?? '',
      eveningReminder: (settings['eveningReminder'] as String?) ?? '',
    );
  }

  // ---------------------------------------------------------------------------
  // Auth session profile
  // ---------------------------------------------------------------------------

  /// Profile milik uid; null bila dokumen belum ada.
  static Future<UserProfile?> loadByUid(String uid) async {
    if (!Backend.useFirebase) return null;
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return _profileFromDoc(snap.id, snap.data()!);
  }

  /// Stream profil realtime — perubahan profil langsung terpancar ke
  /// halaman profil & beranda tanpa reload manual.
  static Stream<UserProfile?> streamByUid(String uid) {
    if (!Backend.useFirebase || uid.isEmpty) return const Stream.empty();
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _profileFromDoc(snap.id, snap.data()!);
    });
  }

  /// Dijalankan tepat setelah `createUserWithEmailAndPassword` sukses.
  /// Provision doc ID = email lowercase (cocok `request.auth.token.email`).
  static Future<void> createProfileOnRegister({
    required String uid,
    required String email,
    required String name,
    required String phone,
  }) async {
    if (!Backend.useFirebase) return;
    final tokenEmail =
        (FirebaseAuth.instance.currentUser?.email ?? email)
            .trim()
            .toLowerCase();
    final normalized = email.trim().toLowerCase();

    Map<String, dynamic>? p;
    try {
      final provSnap = await _provisions.doc(tokenEmail).get();
      if (provSnap.exists &&
          (provSnap.data()?['consumedByUid'] == null) &&
          provSnap.data()?['email'] == tokenEmail) {
        p = provSnap.data();
      }
    } on FirebaseException {
      p = null;
    }

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    if (p != null) {
      // Role dokter atau admin diwariskan dari provision; selain itu pengguna.
      final inheritedRole = (p['role'] as String?) ?? 'pengguna';
      final role = (inheritedRole == 'dokter' || inheritedRole == 'admin')
          ? inheritedRole
          : 'pengguna';
      batch.set(_users.doc(uid), {
        'uid': uid,
        'name': (p['name'] as String?) ?? name,
        'email': normalized,
        'phone': (p['phone'] as String?) ?? phone,
        'address': p['address'],
        'birthDate': p['birthDate'],
        'gender': p['gender'],
        'role': role,
        'status': p['status'] ?? 'aktif',
        'specialization': p['specialization'],
        'experience': p['experience'],
        'str': p['str'],
        'bio': p['bio'],
        'isAvailable': p['isAvailable'] ?? true,
        'settings': p['settings'] ??
            {
              'notificationsEnabled': true,
              'morningReminder': '',
              'eveningReminder': '',
            },
        'createdBy': uid,
        'createdAt': now,
        'updatedAt': now,
      });
      batch.update(_provisions.doc(tokenEmail), {
        'consumedByUid': uid,
        'updatedAt': now,
      });
    } else {
      batch.set(_users.doc(uid), {
        'uid': uid,
        'name': name,
        'email': normalized,
        'phone': phone,
        'role': 'pengguna',
        'status': 'aktif',
        'settings': {
          'notificationsEnabled': true,
          'morningReminder': '',
          'eveningReminder': '',
        },
        'createdBy': uid,
        'createdAt': now,
        'updatedAt': now,
      });
    }
    await batch.commit();
  }

  /// Pendaftaran mandiri akun dokter baru.
  /// Status awal selalu 'menunggu' (memerlukan verifikasi admin sebelum praktik),
  /// isAvailable: false.
  static Future<void> createDoctorProfileOnRegister({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String specialization,
    required String str,
    required String experience,
    required String address,
    String bio = '',
  }) async {
    if (!Backend.useFirebase) return;
    final normalized = email.trim().toLowerCase();
    final tokenEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();

    Map<String, dynamic>? p;
    if (tokenEmail != null) {
      try {
        final provSnap = await _provisions.doc(tokenEmail).get();
        if (provSnap.exists &&
            (provSnap.data()?['consumedByUid'] == null) &&
            provSnap.data()?['email'] == tokenEmail) {
          p = provSnap.data();
        }
      } on FirebaseException {
        p = null;
      }
    }

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(_users.doc(uid), {
      'uid': uid,
      'name': name,
      'email': normalized,
      'phone': phone,
      'address': address,
      'role': 'dokter',
      'status': 'menunggu',
      'specialization': specialization,
      'experience': experience,
      'str': str,
      'bio': bio,
      'isAvailable': false,
      'settings': {
        'notificationsEnabled': true,
        'morningReminder': '',
        'eveningReminder': '',
      },
      'createdBy': uid,
      'createdAt': now,
      'updatedAt': now,
    });

    if (p != null && tokenEmail != null) {
      batch.update(_provisions.doc(tokenEmail), {
        'consumedByUid': uid,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  /// Alasan register ditolak untuk email ini, atau null bila boleh.
  /// Harus dipanggil SETELAH signed in (rules provision butuh sesi Auth).
  static Future<String?> registerBlockReason(String email) async {
    if (!Backend.useFirebase) return null;
    final tokenEmail = FirebaseAuth.instance.currentUser?.email;
    if (tokenEmail == null) return null;
    final normalized = email.trim().toLowerCase();
    if (normalized != tokenEmail.toLowerCase()) {
      return 'Email tidak sesuai sesi pendaftaran.';
    }
    try {
      final snap = await _provisions.doc(normalized).get();
      if (!snap.exists) return null;
      final data = snap.data() ?? const {};
      if (data['consumedByUid'] != null) {
        return 'Undangan untuk email ini sudah digunakan.';
      }
      return null;
    } on FirebaseException {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Admin: daftar pengguna & dokter (registered + provisioned digabung)
  // ---------------------------------------------------------------------------

  static AdminUserModel _adminUserFrom(
    String docId,
    Map<String, dynamic> d, {
    required bool registered,
  }) {
    return AdminUserModel(
      id: docId,
      fsDocId: docId,
      registered: registered,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      birthDate: (d['birthDate'] as String?) ?? '',
      gender: (d['gender'] as String?) ?? '',
      status: userStatusFrom((d['status'] as String?) ?? 'aktif'),
    );
  }

  static AdminDoctorModel _adminDoctorFrom(
    String docId,
    Map<String, dynamic> d, {
    required bool registered,
  }) {
    return AdminDoctorModel(
      id: docId,
      fsDocId: docId,
      registered: registered,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      specialization: (d['specialization'] as String?) ?? '',
      experience: (d['experience'] as String?) ?? '',
      str: (d['str'] as String?) ?? '',
      bio: (d['bio'] as String?) ?? '',
      status: doctorStatusFrom((d['status'] as String?) ?? 'menunggu'),
    );
  }

  static AdminAccountModel _adminAccountFrom(
    String docId,
    Map<String, dynamic> d, {
    required bool registered,
  }) {
    return AdminAccountModel(
      id: docId,
      fsDocId: docId,
      registered: registered,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      birthDate: (d['birthDate'] as String?) ?? '',
      gender: (d['gender'] as String?) ?? '',
      status: userStatusFrom((d['status'] as String?) ?? 'aktif'),
      createdAt: d['createdAt'],
    );
  }

  static Future<List<AdminUserModel>> listPengguna() async {
    if (!Backend.useFirebase) return const [];
    final users = await _users.where('role', isEqualTo: 'pengguna').get();
    final provisions = await _provisions
        .where('role', isEqualTo: 'pengguna')
        .where('consumedByUid', isEqualTo: null)
        .get();
    return [
      ...users.docs
          .map((d) => _adminUserFrom(d.id, d.data(), registered: true)),
      ...provisions.docs
          .map((d) => _adminUserFrom(d.id, d.data(), registered: false)),
    ];
  }

  /// Stream daftar seluruh pengguna secara realtime.
  static Stream<List<AdminUserModel>> streamPengguna() {
    if (!Backend.useFirebase) return const Stream.empty();
    late StreamController<List<AdminUserModel>> controller;
    StreamSubscription? s1;
    StreamSubscription? s2;
    List<AdminUserModel> uList = [];
    List<AdminUserModel> pList = [];

    void emit() {
      if (!controller.isClosed) {
        controller.add([...uList, ...pList]);
      }
    }

    controller = StreamController<List<AdminUserModel>>(
      onListen: () {
        s1 = _users.where('role', isEqualTo: 'pengguna').snapshots().listen(
          (snap) {
            uList = snap.docs
                .map((d) => _adminUserFrom(d.id, d.data(), registered: true))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
        s2 = _provisions
            .where('role', isEqualTo: 'pengguna')
            .where('consumedByUid', isEqualTo: null)
            .snapshots()
            .listen(
          (snap) {
            pList = snap.docs
                .map((d) => _adminUserFrom(d.id, d.data(), registered: false))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        s1?.cancel();
        s2?.cancel();
      },
    );
    return controller.stream;
  }

  static Future<List<AdminDoctorModel>> listDokter() async {
    if (!Backend.useFirebase) return const [];
    final users = await _users.where('role', isEqualTo: 'dokter').get();
    final provisions = await _provisions
        .where('role', isEqualTo: 'dokter')
        .where('consumedByUid', isEqualTo: null)
        .get();
    return [
      ...users.docs
          .map((d) => _adminDoctorFrom(d.id, d.data(), registered: true)),
      ...provisions.docs
          .map((d) => _adminDoctorFrom(d.id, d.data(), registered: false)),
    ];
  }

  /// Stream daftar seluruh dokter secara realtime.
  static Stream<List<AdminDoctorModel>> streamDokter() {
    if (!Backend.useFirebase) return const Stream.empty();
    late StreamController<List<AdminDoctorModel>> controller;
    StreamSubscription? s1;
    StreamSubscription? s2;
    List<AdminDoctorModel> dList = [];
    List<AdminDoctorModel> pList = [];

    void emit() {
      if (!controller.isClosed) {
        controller.add([...dList, ...pList]);
      }
    }

    controller = StreamController<List<AdminDoctorModel>>(
      onListen: () {
        s1 = _users.where('role', isEqualTo: 'dokter').snapshots().listen(
          (snap) {
            dList = snap.docs
                .map((d) => _adminDoctorFrom(d.id, d.data(), registered: true))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
        s2 = _provisions
            .where('role', isEqualTo: 'dokter')
            .where('consumedByUid', isEqualTo: null)
            .snapshots()
            .listen(
          (snap) {
            pList = snap.docs
                .map((d) => _adminDoctorFrom(d.id, d.data(), registered: false))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        s1?.cancel();
        s2?.cancel();
      },
    );
    return controller.stream;
  }

  /// Dokter terverifikasi untuk daftar konsultasi pengguna.
  static Future<List<AdminDoctorModel>> listVerifiedDokter() async {
    if (!Backend.useFirebase) return const [];
    final users = await _users
        .where('role', isEqualTo: 'dokter')
        .where('status', isEqualTo: 'terverifikasi')
        .get();
    return users.docs
        .map((d) => _adminDoctorFrom(d.id, d.data(), registered: true))
        .toList();
  }

  /// Stream daftar dokter terverifikasi secara realtime.
  static Stream<List<AdminDoctorModel>> streamVerifiedDokter() {
    if (!Backend.useFirebase) return const Stream.empty();
    return _users
        .where('role', isEqualTo: 'dokter')
        .where('status', isEqualTo: 'terverifikasi')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _adminDoctorFrom(d.id, d.data(), registered: true))
            .toList());
  }

  /// Daftar seluruh akun admin (terdaftar + undangan provision).
  static Future<List<AdminAccountModel>> listAdmin() async {
    if (!Backend.useFirebase) return const [];
    final users = await _users.where('role', isEqualTo: 'admin').get();
    final provisions = await _provisions
        .where('role', isEqualTo: 'admin')
        .where('consumedByUid', isEqualTo: null)
        .get();
    return [
      ...users.docs
          .map((d) => _adminAccountFrom(d.id, d.data(), registered: true)),
      ...provisions.docs
          .map((d) => _adminAccountFrom(d.id, d.data(), registered: false)),
    ];
  }

  /// Stream realtime seluruh akun admin (terdaftar + undangan provision).
  static Stream<List<AdminAccountModel>> streamAdmin() {
    if (!Backend.useFirebase) return const Stream.empty();
    late StreamController<List<AdminAccountModel>> controller;
    StreamSubscription? s1;
    StreamSubscription? s2;
    List<AdminAccountModel> aList = [];
    List<AdminAccountModel> pList = [];

    void emit() {
      if (!controller.isClosed) {
        controller.add([...aList, ...pList]);
      }
    }

    controller = StreamController<List<AdminAccountModel>>(
      onListen: () {
        s1 = _users.where('role', isEqualTo: 'admin').snapshots().listen(
          (snap) {
            aList = snap.docs
                .map((d) => _adminAccountFrom(d.id, d.data(), registered: true))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
        s2 = _provisions
            .where('role', isEqualTo: 'admin')
            .where('consumedByUid', isEqualTo: null)
            .snapshots()
            .listen(
          (snap) {
            pList = snap.docs
                .map((d) => _adminAccountFrom(d.id, d.data(), registered: false))
                .toList();
            emit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        s1?.cancel();
        s2?.cancel();
      },
    );
    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Admin: tulis (tambah / status)
  // ---------------------------------------------------------------------------

  /// "Tambah Pengguna": bila email sudah terdaftar → update profile-nya,
  /// selain itu tulis pre-provision (tanpa password).
  static Future<AdminUserModel> createPengguna(AdminUserModel u) async {
    if (!Backend.useFirebase) return u;
    final email = u.email.trim().toLowerCase();
    final existing =
        await _users.where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await _users.doc(doc.id).update({
        'name': u.name,
        'phone': u.phone,
        'address': u.address,
        'gender': u.gender,
        'birthDate': u.birthDate,
        'role': 'pengguna',
        'status': userStatusLabel(u.status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return u.copyWith(fsDocId: doc.id, registered: true, email: email);
    }
    // Doc ID = email (required rules register: exists(provisioned_accounts/{token.email})).
    final ref = _provisions.doc(email);
    await ref.set({
      'email': email,
      'name': u.name,
      'phone': u.phone,
      'address': u.address,
      'birthDate': u.birthDate,
      'gender': u.gender,
      'role': 'pengguna',
      'status': userStatusLabel(u.status),
      'settings': {
        'notificationsEnabled': true,
        'morningReminder': '',
        'eveningReminder': '',
      },
      'consumedByUid': null,
      'createdBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return u.copyWith(fsDocId: ref.id, registered: false, email: email);
  }

  static Future<AdminDoctorModel> createDokter(AdminDoctorModel d) async {
    if (!Backend.useFirebase) return d;
    final email = d.email.trim().toLowerCase();
    final existing =
        await _users.where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await _users.doc(doc.id).update({
        'name': d.name,
        'phone': d.phone,
        'specialization': d.specialization,
        'experience': d.experience,
        'str': d.str,
        'bio': d.bio,
        'role': 'dokter',
        'status': doctorStatusLabel(d.status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return d.copyWith(fsDocId: doc.id, registered: true, email: email);
    }
    // Doc ID = email (required rules register path for role dokter).
    final ref = _provisions.doc(email);
    await ref.set({
      'email': email,
      'name': d.name,
      'phone': d.phone,
      'specialization': d.specialization,
      'experience': d.experience,
      'str': d.str,
      'bio': d.bio,
      'role': 'dokter',
      'status': doctorStatusLabel(d.status),
      'isAvailable': d.status == DoctorStatus.terverifikasi,
      'settings': {'notificationsEnabled': true},
      'consumedByUid': null,
      'createdBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return d.copyWith(fsDocId: ref.id, registered: false, email: email);
  }

  static Future<void> updatePenggunaStatus(AdminUserModel u) async {
    if (!Backend.useFirebase) return;
    final col = u.registered ? _users : _provisions;
    await col.doc(u.backendId).update({
      'status': userStatusLabel(u.status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateDokterStatus(AdminDoctorModel d) async {
    if (!Backend.useFirebase) return;
    final col = d.registered ? _users : _provisions;
    final isVerified = d.status == DoctorStatus.terverifikasi;
    await col.doc(d.backendId).update({
      'status': doctorStatusLabel(d.status),
      'isAvailable': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// "Tambah Admin": bila email sudah terdaftar → upgrade role ke admin,
  /// bila belum terdaftar → buat dokumen pre-provision di provisioned_accounts.
  /// Data admin selaras: nama lengkap, nomor telepon, alamat, email, dan password.
  static Future<AdminAccountModel> createAdmin(AdminAccountModel a) async {
    if (!Backend.useFirebase) return a;
    final email = a.email.trim().toLowerCase();
    final existing =
        await _users.where('email', isEqualTo: email).limit(1).get();
    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      await _users.doc(doc.id).update({
        'name': a.name,
        'phone': a.phone,
        'address': a.address,
        'role': 'admin',
        'status': userStatusLabel(a.status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return a.copyWith(fsDocId: doc.id, registered: true, email: email);
    }
    // Doc ID = email (cocok rules register).
    final ref = _provisions.doc(email);
    await ref.set({
      'email': email,
      'name': a.name,
      'phone': a.phone,
      'address': a.address,
      'initialPassword': a.password,
      'role': 'admin',
      'status': userStatusLabel(a.status),
      'settings': {
        'notificationsEnabled': true,
        'morningReminder': '',
        'eveningReminder': '',
      },
      'consumedByUid': null,
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return a.copyWith(fsDocId: ref.id, registered: false, email: email);
  }

  /// Update status akun admin (aktifkan / tangguhkan).
  /// Menolak penangguhan terhadap akun admin yang sedang login.
  static Future<void> updateAdminStatus(AdminAccountModel a) async {
    if (!Backend.useFirebase) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (a.registered && currentUid != null && a.backendId == currentUid) {
      throw StateError('Anda tidak dapat menangguhkan akun admin Anda sendiri.');
    }
    final col = a.registered ? _users : _provisions;
    await col.doc(a.backendId).update({
      'status': userStatusLabel(a.status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Update profile milik sendiri & pengaturan
  // ---------------------------------------------------------------------------

  static Future<void> updateOwnProfile(
    String uid, {
    required Map<String, dynamic> fields,
  }) async {
    if (!Backend.useFirebase) return;
    await _users.doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSettings(
    String uid, {
    bool? notificationsEnabled,
    String? morningReminder,
    String? eveningReminder,
  }) async {
    if (!Backend.useFirebase) return;
    final fields = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Dot-notation → merge ke map `settings` (bukan replace seluruh map).
    if (notificationsEnabled != null) {
      fields['settings.notificationsEnabled'] = notificationsEnabled;
    }
    if (morningReminder != null) {
      fields['settings.morningReminder'] = morningReminder;
    }
    if (eveningReminder != null) {
      fields['settings.eveningReminder'] = eveningReminder;
    }
    await _users.doc(uid).update(fields);
  }

  /// UID seluruh admin — dipakai fan-out notifikasi platform ke admin.
  ///
  /// Hanya admin yang boleh menjalankan query ini (Security Rules menilai
  /// `isAdmin()` per dokumen hasil), sehingga non-admin selalu menerima
  /// `permission-denied` dan method ini melempar error.
  static Future<List<String>> listAdminUids() async {
    if (!Backend.useFirebase) return const [];
    final snap = await _users.where('role', isEqualTo: 'admin').get();
    return snap.docs.map((d) => d.id).where((id) => id.isNotEmpty).toList();
  }

  /// UID pengguna aktif yang terdaftar (fan-out artikel edukasi, dsb).
  static Future<List<String>> listPenggunaUids({int limit = 500}) async {
    if (!Backend.useFirebase) return const [];
    final snap =
        await _users.where('role', isEqualTo: 'pengguna').limit(limit).get();
    return snap.docs.map((d) => d.id).where((id) => id.isNotEmpty).toList();
  }

  // ---------------------------------------------------------------------------
  // Statistik dashboard (agregat kueri — tanpa counter tersimpan)
  // ---------------------------------------------------------------------------

  static Future<int> countPengguna() async =>
      _count(_users.where('role', isEqualTo: 'pengguna'));

  static Future<int> countDokter() async =>
      _count(_users.where('role', isEqualTo: 'dokter'));

  static Future<int> countDokterAktif() async => _count(_users
      .where('role', isEqualTo: 'dokter')
      .where('status', isEqualTo: 'terverifikasi'));

  static Future<int> countAdmin() async =>
      _count(_users.where('role', isEqualTo: 'admin'));

  static Future<int> _count(Query<Map<String, dynamic>> q) async {
    if (!Backend.useFirebase) return 0;
    try {
      final snap = await q.count().get();
      return snap.count ?? 0;
    } on FirebaseException catch (e) {
      debugPrint('count fallback: ${e.message}');
      final snap = await q.get();
      return snap.docs.length;
    }
  }
}

/// Helper logging aktivitas dipakai service lain.
Future<void> logActivity({
  required String title,
  required String tag,
  required String actor,
  required String actorUid,
}) {
  return ActivityService.log(
    title: title,
    tag: tag,
    actor: actor,
    actorUid: actorUid,
  );
}
