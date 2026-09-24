# Skinora — System Map (Audit Pre-Implementasi + Desain Backend)

Dokumen ini adalah hasil **reverse-engineering menyeluruh** terhadap source code `skinora_app`
sebelum implementasi backend, sekaligus acuan desain Firebase (Authentication, Firestore,
Security Rules, Indexes). Semua isinya diturunkan dari kode, bukan asumsi.

---

## 1. Kondisi Awal Hasil Audit (Pre-Implementasi)

| Aspek | Temuan |
|---|---|
| State management | Tidak ada. Murni `setState` per halaman. Tidak ada Provider/Riverpod/Bloc/GetX. |
| Architecture | Tidak ada layer service/repository/controller. Semua data hardcoded di dalam widget. |
| Persistence | Tidak ada. Nol penyimpanan (tidak ada SharedPreferences/SQLite/http). |
| Auth | Palsu. `LoginPage._handleLogin` hanya memeriksa string input (`contains('admin')` / `dokter` / else) lalu navigate. Password tidak pernah dicek. `RegisterPage` hanya menampilkan Snackbar. |
| Storage | Tidak ada upload file/gambar/apa pun. Avatar = inisial huruf. **Firebase Storage tidak diperlukan.** |
| Firebase | Hanya `android/app/google-services.json` (project `skinora-app`) yang menganggur — plugin google-services tidak dipasang, `firebase_core` tidak ada. |
| Testing | `test/widget_test.dart`: 52 widget test yang memompa page secara langsung dan menguji UI/interaksi lokal. |
| Navigation | Named routes di `main.dart` + banyak `MaterialPageRoute` anonim. 3 shell tab: `AdminMainPage`, `DokterMainPage`, `PenggunaMainPage` (IndexedStack 5 tab masing-masing). |
| Platform | Android: `com.example.skinora_app` (applicationId). iOS bundle: `com.example.skinoraApp`, tanpa `GoogleService-Info.plist`. |

---

## 2. Role Pengguna

Role **tersirat dari UI dan jalur navigasi login** (tidak ada pengecekan role di dalam page).

| Role | Shell | Login routing (kode lama) | Hak akses implisit |
|---|---|---|---|
| `pengguna` (pasien) | `PenggunaMainPage` | input selain admin/dokter (default) | Kelola data kesehatan diri, booking dokter, chat, baca edukasi |
| `dokter` | `DokterMainPage` | input contains `dokter`/`doctor` | Jadwal, konsultasi pasien, insight pasien, profil praktik |
| `admin` | `AdminMainPage` | input contains `admin` | Master data, verifikasi dokter, kelola pengguna/artikel, laporan |

### Role ↔ Fitur ↔ Screen (ringkas)

**admin** (tab: Beranda, Dokter, Pengguna, Edukasi, Profil)
- Beranda: statistik hardcoded, aktivitas terbaru, menu cepat (Dokter/Pengguna/Edukasi/Spesialisasi/Laporan), lonceng notifikasi.
- Manajemen Dokter: search, filter status (`Semua/Pending/Terverifikasi/Ditolak/Ditangguhkan`), tambah dokter (form: nama*, email*, telepon, spesialisasi*, pengalaman, STR, bio → status `menunggu`), detail + aksi Verifikasi/Tolak/Tangguhkan/Aktifkan.
- Manajemen Pengguna: search, tambah pengguna (nama*, email*, telepon, alamat, jenis kelamin → status `aktif`), detail + aksi Tangguhkan/Aktifkan. *(Tidak ada form edit profil pengguna.)*
- Manajemen Edukasi (artikel): search, filter status, tambah/edit (judul*, kategori*, status toggle draf/diterbitkan, konten), Terbit/Tolak Terbit, Hapus (confirm dialog).
- Master Spesialisasi: CRUD nama + toggle aktif/nonaktif + hapus.
- Laporan Riwayat: agregat statistik + daftar aktivitas lintas-user (filter kategori + search).
- Notifikasi, Profil (+ edit nama/telepon/alamat), Pengaturan (toggle notifikasi), Riwayat Aktivitas, Tentang, Logout.

**dokter** (tab: Beranda, Jadwal, Chat, Riwayat, Profil)
- Beranda: sapaan nama + spesialisasi, statistik hari ini, slot jadwal hari ini, akses cepat (Jadwal/Konsultasi/Insight), lonceng notifikasi.
- Jadwal: toggle ketersediaan `Siap/Sibuk`, tambah slot (tanggal, jam mulai, jam selesai), hapus slot (hanya yang belum dibooking).
- Chat/Konsultasi: daftar konsultasi `Terjadwal`/`Berlangsung`, aksi "Mulai Konsultasi"/"Masuk Ruang Chat" → ruang chat, kirim pesan, "Selesai" (confirm) → arsip ke Riwayat (+diagnosis/notes otomatis).
- Riwayat: konsultasi `Selesai` → detail (transkrip chat).
- Patient Insight: daftar pasien (jumlah konsultasi, tipe kulit, concern terakhir, konsultasi terakhir) → detail (kondisi kulit teratas, stat air/tidur/skincare, insight, riwayat skin check, skin daily, skincare routine) + ganti pasien (bottom sheet).
- Profil: ringkasan praktik, info dokter, edit profil (nama*, spesialisasi, pengalaman, telepon, alamat, bio), Pengaturan, Riwayat Aktivitas, Tentang, Logout.
- Notifikasi.

**pengguna** (tab: Beranda, Skin Check, Skin Daily, Skincare, Profil)
- Beranda: sapaan nama, ringkasan hari ini (Skin Check/Skin Daily/Skincare/Chat), menu cepat, tips, lonceng notifikasi.
- Skin Check: landing (riwayat + mulai) → rantai 7 pertanyaan (usia, jenis kelamin, kondisi setelah cuci, minyak, sensitivitas, kelembapan, suhu) → hasil (jenis kulit, sensitivitas, risiko jerawat, tips) → riwayat skin check.
- Skin Daily: form (tanggal, lokasi gejala, gejala kulit, kebiasaan, jam tidur, air, makanan, aktivitas, switch skincare pagi/malam, Simpan) → riwayat (expand card), Insight Kulit (agregat 7 hari).
- Skincare: checklist rutinitas pagi (8 langkah) & malam (13 langkah), Simpan Paga/Malam → riwayat.
- Konsultasi Dokter: daftar dokter terverifikasi (search + chip kategori), profil dokter + jadwal slot → booking (dialog "Menunggu Dokter..." 3 detik) → ruang konsultasi (chat), Riwayat konsultasi → transkrip.
- Edukasi: daftar artikel terbit (search + chip kategori) → detail.
- Profil: info diri, edit (nama/telepon/alamat), Pengaturan (toggle + pengingat pagi/malam), Riwayat Aktivitas, Tentang, Logout.
- Notifikasi.

---

## 3. Reverse Engineering: Data Flow per Fitur (sebelum → sesudang)

Notasi: **[L]** = lokal/setState saja ( kondisi awal ), **[F]** = target Firestore.

### 3.1 Autentikasi
| Aksi | Alur awal | Alur final |
|---|---|---|
| Login | tebak role dari string email, tanpa password | `signInWithEmailAndPassword` → baca `users/{uid}` → cek `status` → route per `role` → tulis activity `Login berhasil`. Error → `_errorMessage` (slot error yang sudah ada). |
| Register | Snackbar + langsung ke `PenggunaMainPage` / `DokterMainPage` (provision) | `registerBlockReason` (tolak role admin) → `createUserWithEmailAndPassword` → buat `users/{uid}` (role `pengguna`, atau warisan `dokter` dari `provisioned_accounts`) → route per role. Admin tidak bisa register. |
| Lupa password | SnackBar "belum tersedia" | `sendPasswordResetEmail` → SnackBar "Email reset password telah dikirim." |
| Logout | navigasi saja | `signOut()` + navigasi `/login` (kontrak navigasi dipertahankan). |
| Session | tidak ada | Firebase Auth persistence + auto-redirect dari `LoginPage` bila sudah login + listener `authStateChanges` di `main()`. |

### 3.2 Data pengguna & profil
| Fitur | Awal | Final |
|---|---|---|
| Profil pengguna/dokter/admin | field hardcoded di page | baca/tulis `users/{uid}` |
| Edit profil | pop `Map` → setState page | tulis `users/{uid}` (field yang diizinkan) lalu pop (kontrak pop dipertahankan) |
| Admin tambah pengguna/dokter | model in-memory | tulis `provisioned_accounts` (pre-provision) — akun Auth dibuat saat orang itu mendaftar dengan email tersebut (lihat §5) |
| Tangguhkan/Verifikasi/Tolak | copyWith + setState | update `status` di `users/{uid}` / `provisioned_accounts/{id}` oleh admin |
| Pengaturan (notifikasi/pengingat) | SnackBar saja | update `users/{uid}.settings` |

### 3.3 Master & konten (admin)
| Fitur | Awal | Final |
|---|---|---|
| Spesialisasi | list lokal | collection `specializations` (CRUD, hanya admin tulis) |
| Artikel | list lokal | collection `articles` (admin tulis; pengguna baca `status == 'diterbitkan'`) |
| Dropdown spesialisasi di form dokter | hardcoded di page | dibaca dari `specializations` (fallback hardcoded bila Firebase tak tersedia) |

### 3.4 Konsultasi & chat
| Fitur | Awal | Final |
|---|---|---|
| Booking slot | dialog 3 detik, tak ada record | batch transaction: slot `isBooked=true` + dokumen `consultations` + `care_links` + activity + notifikasi dokter |
| Chat | list pesan lokal, hilang saat pop | subcollection `consultations/{id}/messages` (stream snapshots) |
| Selesai konsultasi | hapus dari list + singleton | update `status='selesai'` (batch dengan activity) |
| Riwayat (dokter & pengguna) | hardcoded / singleton | query `consultations` per dokter/pasien |
| Daftar konsultasi aktif dokter | hardcoded | `consultations where doctorId == uid`, status ≠ selesai |

### 3.5 Jadwal dokter
| Fitur | Awal | Final |
|---|---|---|
| Slot | list per-hari di state | subcollection `users/{doctorUid}/slots` |
| Siap/Sibuk | state page | `users/{uid}.isAvailable` |
| Hapus slot | lokal | hapus doc (hanya slot belum dibooking) |

### 3.6 Data kesehatan pengguna
| Fitur | Awal | Final |
|---|---|---|
| Skin Check hasil | tidak pernah disimpan (riwayat statis 2 item) | `users/{uid}/skin_checks` (jawaban + hasil); riwayat dibaca dari sana |
| Skin Daily Simpan | SnackBar saja | `users/{uid}/skin_dailies` (+ status turunan Baik/Sedang/Buruk) |
| Riwayat/Insight Skin Daily | 7 entri statis | dibaca + diagregasi dari `skin_dailies` |
| Skincare Simpan | SnackBar saja | `users/{uid}/skincare_logs` (upsert per tanggal) |
| Ringkasan Beranda pengguna | hardcoded | turunan dari dokumen terakhir pengguna |
| Patient Insight dokter | 5 pasien statis | turunan dari `care_links` + `consultations` + data kesehatan pasien |

### 3.7 Notifikasi, aktivitas, laporan
| Fitur | Awal | Final |
|---|---|---|
| Notifikasi per role | 2–4 item statis, mark-read lokal | collection `notifications` (audience per-user / role:admin); update hanya `isUnread` |
| Riwayat aktivitas per role | statis | collection `activities` (actorUid) |
| Laporan admin | 12 entri statis + angka statis | agregat kueri `activities`/`consultations`/`users`/`articles` (tanpa counter tersimpan → bebas race) |
| Statistik beranda | hardcoded | agregat kueri (`count` server-side) |

### 3.8 Data yang TIDAK masuk Firestore (UI-state saja)
- State tab, chip filter, query search, teks expand/collapse, nilai form sementara,
  `_obscurePassword`, `_rememberMe` (UI checkbox; sesi sebenarnya ditangani Firebase Auth),
  ikon/`IconData` (di-map dari `tag`/`iconKey` di client), warna badge, template body
  artikel panjang di `detail_edukasi_page` (template konten statis UI — konten artikel
  yang diedit admin tetap dibaca dari field `content`), teks "Tips Hari Ini", disclaimer,
  halaman "Tentang".

---

## 4. Desain Database Firestore

### 4.1 Koleksi & Field

**`users/{uid}`** — dokumen ID = UID Firebase Auth (identitas utama).
```
uid: string, name: string, email: string, phone: string, address: string,
birthDate: string, gender: string,
role: 'pengguna'|'dokter'|'admin',
status: string  // pengguna/admin: 'aktif'|'ditangguhkan'
                // dokter: 'menunggu'|'terverifikasi'|'ditolak'|'ditangguhkan'
// khusus dokter:
specialization: string?, experience: string?, str: string?, bio: string?,
isAvailable: bool?,
// pengaturan:
settings: map { notificationsEnabled: bool, morningReminder: string?, eveningReminder: string? },
createdBy: string, createdAt: Timestamp(server), updatedAt: Timestamp(server)
```
Subcollection milik pengguna: `skin_checks`, `skin_dailies`, `skincare_logs`.
Subcollection milik dokter: `slots`.

**`provisioned_accounts/{emailLowercase}`** — doc ID **wajib** = email lowercase
(sama dengan `request.auth.token.email` di Security Rules). Akun dibuat admin,
belum punya Auth account.
```
email, name, phone, address, birthDate, gender, role, status,
specialization?, experience?, str?, bio?,
consumedByUid: string? (null = belum didaftarkan),
createdBy, createdAt, updatedAt
```

**`specializations/{autoId}`**: `name: string, isActive: bool, createdBy, createdAt, updatedAt`

**`articles/{autoId}`** (seed demo memakai id `'1'`–`'7'` agar template detail lama tetap cocok):
```
title, category, date (string 'yyyy-MM-dd'), content, status: 'diterbitkan'|'draf',
createdBy, updatedBy, createdAt, updatedAt
```

**`activities/{autoId}`** (immutable / write-only):
```
title, tag ('Login'|'Skin Check'|'Skin Daily'|'Skincare'|'Booking'|'Konsultasi'|'Review'|'Verifikasi'|'Artikel'|'Profil'|'Pengguna'|'Dokter'|'Spesialisasi'),
actor (string — harus = users/{uid}.name, diverifikasi rules), actorUid, createdBy, createdAt: Timestamp
// tampilan 'yyyy-MM-dd HH:mm' diturunkan client dari createdAt; ikon diturunkan dari tag.
```

**`notifications/{autoId}`**:
```
audience: 'user:{uid}' | 'role:admin',
recipientUid: string ('' utk broadcast role:admin) — diverifikasi rules via care_link/self/admin,
type: 'dokter'|'user'|'konsultasi'|'booking'|'jadwal'|'ringkas'|..., // menentukan aksi tap
title, description, iconKey, isUnread: bool, createdBy, createdAt
```

**`care_links/{patientUid_doctorId}`** — hubungan perawatan dibuat saat booking:
```
patientId, doctorId, slotId?, createdBy (patientId), createdAt
```

**`consultations/{slotId}`** — ID deterministik = slotId (anti double-book):
```
patientId, patientName, doctorId, doctorName, specialization,
scheduleDate (string tampil 'Jumat, 28 Agustus 2026'), dateIso ('yyyy-MM-dd'),
scheduleTime ('09:00 - 09:30'), timeStart, timeEnd,
status: 'terjadwal'|'berlangsung'|'selesai',
diagnosis: string?, notes: string?,
slotId: string?, createdBy, createdAt, updatedAt
// Subcollection: messages/{autoId}: senderId, senderRole ('user'|'dokter'), text, time('HH:mm'), createdAt
```

**`users/{uid}/skin_checks/{autoId}`**:
```
age, gender, conditionAfterWash, oilCondition, sensitivity, humidity, temperature,
resultSkinType, resultSensitivity, resultAcneRisk, createdBy, createdAt
```

**`users/{uid}/skin_dailies/{dateIso}`** — doc ID = dateIso (upsert per hari):
```
dateDisplay ('Jumat, 28 Agustus 2026'), dateIso, locations[]: string, symptoms[]: string,
kebiasaan, jamTidur, air, makanan, aktivitas,
skincarePagi: bool, skincareMalam: bool, status ('Baik'|'Sedang'|'Buruk' — turunan),
createdBy, createdAt, updatedAt
```

**`users/{uid}/skincare_logs/{dateIso}`** — doc ID = dateIso (upsert per tanggal):
```
dateDisplay, dateIso, morningSteps[]: string, nightSteps[]: string,
createdBy, createdAt, updatedAt
```

**`users/{doctorUid}/slots/{autoId}`**:
```
date (string tampil), time ('09:00 - 09:30'), timeStart, timeEnd,
isBooked: bool, patientId: string?, patientName: string?,
createdBy, createdAt, updatedAt
```

### 4.2 Relationship
```
users(1) ──< users.skin_checks (ownership: patient)
users(1) ──< users.skin_dailies
users(1) ──< users.skincare_logs
users(1) ──< users.slots                 (dokter)
users(1) >──< users(1) via care_links    (pasien ↔ dokter, dibuat saat booking)
users(1) ──< consultations (patientId)   (1 pasien : N konsultasi)
users(1) ──< consultations (doctorId)    (1 dokter : N konsultasi)
consultations(1) ──< consultations.messages
provisioned_accounts(1) ──> users(0..1)  (dikonsumsi saat register: consumedByUid)
specializations (master) ── dipakai admin & pengguna (chip/filter)
articles (milik admin) ── dibaca pengguna (status terbit)
activities, notifications ── di-*reference* actor/recipient (bukan relasi wajib)
```

### 4.3 Klasifikasi data
| Kategori | Contoh |
|---|---|
| Authentication state | sesi Firebase Auth, current user, role dari `users/{uid}` |
| Persistent application data | profil, artikel, spesialisasi, konsultasi, chat, jadwal, data kesehatan, notifikasi, aktivitas, pengaturan |
| Master data | `specializations` |
| Transaction data | `consultations` + `messages` + booking slot (batch) |
| Derived/calculated | statistik dashboard, insight, agregat laporan, status skin daily, badge — dihitung dari kueri, **tanpa counter tersimpan** (hindari race) |
| UI state (tidak di-Firestore) | filter, search, tab, expand, ikon, warna |

---

## 5. Authentication Flow

```
App start → Firebase.initializeApp (firebase_options.dart)
LoginPage.initState → authStateChanges/currentUser != null ? → load profile → route per role
                       ↓ belum login
[input email+password] → signInWithEmailAndPassword
      ├─ FirebaseAuthException → pesan Indonesia → _errorMessage (slot error existing)
      ├─ users/{uid} tidak ada → signOut + error
      ├- status 'ditangguhkan'/'ditolak' → signOut + error "Akun Anda ditangguhkan."
      └- sukses → write activity 'Login berhasil' → pushReplacement shell role:
            role 'admin'  → AdminMainPage
            role 'dokter' → DokterMainPage
            else          → PenggunaMainPage

RegisterPage → validasi existing → createUserWithEmailAndPassword
      → batch: create users/{uid} (+ konsumsi provisioned_accounts bila email cocok)
      → pushReplacement shell sesuai role (default 'pengguna' → PenggunaMainPage)

LogoutDialog confirm → signOut() → pushNamedAndRemoveUntil('/login')

main(): listener authStateChanges → null → navigasi global ke '/login' (guard logout dari luar)
Guard halaman shell: bila Firebase aktif & belum login / role tidak cocok → redirect '/login'
                     (guard dilewati ketika Firebase tidak diinisialisasi → widget test tetap jalan)
```

**Pre-provision (admin menambah pengguna/dokter tanpa password):**
admin hanya menulis `provisioned_accounts` (tanpa kredensial — password tidak pernah
disimpan di Firestore). Orang tersebut mendaftar sendiri dengan email yang sama;
saat register, `role`/profile diwariskan dari provision lalu provision ditandai
`consumedByUid`. Batasan terdokumentasi: email belum diverifikasi saat link terjadi.

---

## 6. Permission Matrix (acuan Security Rules — least privilege)

Ikon: R=Read, C=Create, U=Update, D=Delete. `owner` = `request.auth.uid` terkait.

| Collection / path | pengguna | dokter | admin | Catatan |
|---|---|---|---|---|
| `users/{uid}` (own) | R,U | R,U | R,U | field `role`,`uid`,`email`,`status`,`createdBy`,`createdAt` **immutable** bagi non-admin; `settings` + profil boleh diubah owner (settings di-merge via dot-notation) |
| `users/{uid}` (other) | — | — | R,U | admin boleh ubah `status`/profile; tetap tak bisa ubah `uid` |
| `users` (list) | R (uid sendiri) | R (uid sendiri) | R (semua) | list non-admin wajib difilter `where uid ==` sendiri |
| `users` create | C role `pengguna`/`dokter` saja | C role `dokter` (via provision) | — | client **tidak** boleh buat role `admin` |
| `provisioned_accounts` | — (kecuali link saat register: R/U sekali) | — | R,C,U,D | register: R+U oleh pendaftar bila `email == token.email && consumedByUid == null` |
| `users/{p}/skin_checks` | owner C,R | R jika `care_links/{p}_{doctor}` ada | R | update/delete: tidak ada (riwayat immutable) |
| `users/{p}/skin_dailies` | owner C,R,U,D | R jika care_link | R | |
| `users/{p}/skincare_logs` | owner C,R,U | R jika care_link | R | |
| `users/{d}/slots` | R (authenticated) untuk melihat jadwal; booking: U terbatas (`isBooked false→true`, isi patient) oleh pasien | C,U,D sendiri (U booking hanya dokter sendiri kecept booking rule) | R | slot terbooking tidak boleh dihapus/diubah selain transisi booking |
| `care_links/{p}_{d}` | C bila `patientId == uid`; R pasien & dokter terkait | R | R | id wajib `patientId_doctorId` |
| `consultations` | C/R/U (partisipan; C wajib `patientId == uid`) | R/U partisipan (update `status`,`diagnosis`,`notes`) | R | field `patientId/doctorId/patientName/doctorName` immutable |
| `consultations/{id}/messages` | R/C partisipan | R/C partisipan | R | `senderId` wajib == uid |
| `specializations` | R | R | R,C,U,D | |
| `articles` | R (terbit saja) | R (terbit saja) | R,C,U,D | list non-admin dibuktikan dengan filter `status == 'diterbitkan'` |
| `activities` | R (actorUid sendiri), C (actorUid/createdBy == sendiri) | sama | R semua, C sendiri | immutable (U/D: hanya admin D bila perlu — default tanpa U) |
| `notifications` `user:{uid}` | R,U (owner; U hanya `isUnread`) | C ke pasien (care_link) / ke diri | R | |
| `notifications` `role:admin` | — | C? (tidak perlu) | R,U(`isUnread`), C oleh user terautentikasi saat registrasi (audience `role:admin`, `createdBy == uid`) | dibatasi field wajib |

Prinsip: **setiap jalur diverifikasi di rules** — menyembunyikan tombol di UI tidak dianggap keamanan.
Manipulasi `role`/`status`/`ownerId` dari client di blokir oleh field-immutability rules.

---

## 7. Query → Kebutuhan Index

| # | Query | Kebutuhan index |
|---|---|---|
| 1 | `activities.where(actorUid==).orderBy(createdAt desc)` | **komposit** `(actorUid ASC, createdAt DESC)` |
| 2 | `activities.orderBy(createdAt desc)` (admin laporan) | single-field (bawaan) |
| 3 | `notifications.where(audience==).orderBy(createdAt desc)` | **komposit** `(audience ASC, createdAt DESC)` |
| 4 | `articles.where(status=='diterbitkan').orderBy(createdAt desc)` | **komposit** `(status ASC, createdAt DESC)` |
| 5 | `consultations.where(doctorId==).orderBy(createdAt desc)` | **komposit** `(doctorId ASC, createdAt DESC)` |
| 6 | `consultations.where(patientId==).orderBy(createdAt desc)` | **komposit** `(patientId ASC, createdAt DESC)` |
| 7 | `users.where(role==)`, `where(email==)`, `where(uid==)`, `where(status==)` (equality murni) | single-field / zig-zag — tanpa komposit |
| 8 | `provisioned_accounts.where(email==).where(consumedByUid==null)` | equality murni — tanpa komposit |
| 9 | subcollections (`skin_checks` dkk.) `orderBy(createdAt)` | single-field per koleksi |
| 10 | `messages.orderBy(createdAt asc)` | single-field |

Filter tambahan (status konsultasi, pencarian, dsb.) dilakukan **di client** setelah
equality utama → tidak menambah index yang tidak perlu.

---

## 8. Batasan / Keputusan Teknis Terdokumentasi

1. **Firebase Storage tidak diimplementasikan** — tidak ada fitur upload di UI manapun.
2. **Password** hanya hidup di Firebase Auth; tidak pernah disentuh Firestore.
3. **Tidak ada Admin SDK/service account** di aplikasi Flutter. Seeder opsional membaca
   `GOOGLE_APPLICATION_CREDENTIALS` dari environment (tidak masuk repo).
4. **Fallback demo**: bila `Firebase.apps` kosong (widget test / Firebase belum terinit),
   service mengembalikan seed data UI yang lama dan write di-skip. Ini dipertahankan
   **hanya** agar 52 widget test UI existing tetap hijau tanpa emulator; jalur produksi
   selalu Firestore ketika Firebase terinit (dipastikan oleh `main()` yang me-init Firebase).
5. **iOS**: `google-services.json` hanya berisi klien Android; konfigurasi iOS perlu
   pendaftaran app di konsol Firebase (didokumentasikan di BACKEND.md).
6. **Agregat/counter** dihitung via kueri `count`/panjang list, bukan dokumen counter →
   bebas race condition; booking konsultasi+slot memakai **batch/transaction**.
