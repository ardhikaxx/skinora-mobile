# Skinora — Backend (Firebase) Dokumentasi Teknis

Dokumen operasional integrasi Firebase Authentication + Cloud Firestore untuk
`skinora_app`. Desain lengkap ada di [`SYSTEM_MAP.md`](./SYSTEM_MAP.md).

---

## 1. Stack & Keputusan

| Komponen | Pilihan | Catatan |
|---|---|---|
| Auth | Firebase Authentication — Email & Password | UID Auth = primary key `users/{uid}` |
| Database | Cloud Firestore | Tanpa Storage (tidak ada fitur upload) |
| State | `setState` existing | Service layer tipis, tanpa Provider/Bloc |
| Config | `lib/firebase_options.dart` | Project `skinora-app` |
| Switch | `Backend.useFirebase` (`Firebase.apps.isNotEmpty`) | false di widget test → seed demo |

Password hanya hidup di Firebase Auth. Tidak pernah ditulis ke Firestore.

---

## 2. Cara Menjalankan

```bash
# 1. Pastikan Firebase CLI login
firebase login

# 2. Deploy rules + indexes
firebase deploy --only firestore:rules,firestore:indexes

# 3. (Opsional) seed data demo
GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
  PROJECT_ID=skinora-app node tool/seed.mjs

# 4. Jalankan aplikasi
flutter run
```

### Emulator (lokal, tanpa production)

```bash
firebase emulators:start --only auth,firestore
# HOST default: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
# (opsional: set di main() saat development)
```

---

## 3. Struktur Koleksi (ringkas)

```
users/{uid}                          # profile + role + settings
users/{uid}/skin_checks/{id}
users/{uid}/skin_dailies/{id}
users/{uid}/skincare_logs/{id}
users/{doctorUid}/slots/{id}
provisioned_accounts/{emailLowercase}   # doc ID = email lowercase (wajib utk rules)
specializations/{id}
articles/{id}
activities/{id}                      # immutable log
notifications/{id}                   # audience: user:{uid} | role:admin
care_links/{patientId_doctorId}
consultations/{id}
consultations/{id}/messages/{id}
```

Field detail: [`SYSTEM_MAP.md` §4](./SYSTEM_MAP.md).

---

## 4. Composite Indexes

| Collection | Fields |
|---|---|
| `activities` | `actorUid` ASC, `createdAt` DESC |
| `notifications` | `audience` ASC, `createdAt` DESC |
| `articles` | `status` ASC, `createdAt` DESC |
| `consultations` | `doctorId` ASC, `createdAt` DESC |
| `consultations` | `patientId` ASC, `createdAt` DESC |
| `slots` (group) | `isBooked` ASC, `createdAt` ASC (bookable stream) |
| `provisioned_accounts` | `role` ASC, `consumedByUid` ASC |
| `users` | `role` ASC, `status` ASC |
| `users` | `role` ASC, `specialization` ASC (cascade rename) |

File: [`firestore.indexes.json`](../firestore.indexes.json).

---

## 5. Security Rules (ringkas)

File: [`firestore.rules`](../firestore.rules).

Prinsip:
- Least privilege; setiap path diverifikasi (bukan hanya menyembunyikan tombol).
- Field immutable bagi non-admin: `role`, `uid`, `email`, `status` (owner).
- `activities` create-only (client) — update selalu ditolak.
- Booking slot: dokter boleh C/U/D slot miliknya; pasien hanya U `isBooked false→true`.
- Chat `messages`: hanya partisipan `patientId`/`doctorId` konsultasi; create-only.
- Skin check history: immutable (create/read saja).
- Notification update: hanya `isUnread` oleh penerima / admin.

Permission matrix lengkap: [`SYSTEM_MAP.md` §6](./SYSTEM_MAP.md).

---

## 6. Auth Flow

```
Register → createUserWithEmailAndPassword → batch users/{uid} (+ konsumsi provision)
           (hanya pengguna & dokter provision; role admin ditolak)
Login     → signInWithEmailAndPassword → baca users/{uid} → cek status → route per role
Logout    → signOut → /login
```

Shell pages (`*_main_page`) punya guard `_ensureSignedIn()` → redirect `/login`
saat Firebase aktif & sesi null. Guard dilewati di widget test (`Backend.useFirebase == false`).

---

## 7. Pre-Provision (Admin Tambah Pengguna/Dokter)

Admin **tidak membuat password**. Alur:
1. Admin menulis `provisioned_accounts` (email, role, profile) — `consumedByUid: null`.
2. Orang tersebut register sendiri dengan email sama.
3. `createProfileOnRegister` mewarisi role/profile lalu set `consumedByUid`.

---

## 8. Data yang TIDAK di-Firestore

Tab, filter, search, expand, ikon, warna, password, remember-me checkbox,
tips harian statis, disclaimer, halaman Tentang.

---

## 9. Fallback Demo

`Backend.useFirebase == false` (Firebase belum terinit / widget test):
- Service return seed data UI lama (atau empty untuk list).
- Write di-skip (lokal `setState` saja).
- 52 widget test tetap hijau tanpa emulator.

Jalur produksi: `main()` selalu `Firebase.initializeApp` → semua service pakai Firestore.

---

## 10. iOS

`google-services.json` hanya Android. Untuk iOS:
1. Daftarkan app di konsol Firebase (`com.example.skinoraApp`).
2. Download `GoogleService-Info.plist` → tambah ke Runner.
3. Jalankan `flutterfire configure` bila perlu regenerate `firebase_options.dart`.

---

## 11. Troubleshooting

| Gejala | Solusi |
|---|---|
| `failed-precondition` saat query | Index belum ada → cek link error / `firestore.indexes.json` |
| `permission-denied` | Cek rules; pastikan `users/{uid}.role` benar |
| Seed tidak muncul di UI | Pastikan `Firebase.apps.isNotEmpty` (Firebase terinit) |
| Test hijau tapi app kosong | Firebase tidak terinit di runtime → cek `firebase_options.dart` |

---

## 12. Perintah Verifikasi

```bash
flutter analyze --no-fatal-infos   # harus "No issues found"
flutter test                        # 52 test harus All tests passed
```
