# Integrasi SATUSEHAT (Mode Sandbox — Resource Patient)

Dokumen teknis implementasi integrasi **SATUSEHAT Kemenkes RI** pada `skinora_app` dengan fokus awal pada pengiriman dan sinkronisasi **data pasien / pengguna (`Patient` FHIR R4)** menggunakan environment **Sandbox / Staging**.

---

## 1. Ringkasan Arsitektur & File Terkait

| Komponen | Lokasi | Fungsi |
|---|---|---|
| Konfigurasi Environment & Kredensial | [`lib/services/satusehat_config.dart`](../lib/services/satusehat_config.dart) | Mengatur environment (`sandbox` / `production`), `organizationId`, `clientId`, `clientSecret`, dan base URL (`--dart-define` didukung). |
| Model Data SATUSEHAT | [`lib/models/satusehat_models.dart`](../lib/models/satusehat_models.dart) | Model wilayah administratif, info `Organization`, opsi `maritalStatus`, input pasien, hasil sinkronisasi, dan `SatuSehatException`. |
| Layanan API SATUSEHAT | [`lib/services/satusehat_service.dart`](../lib/services/satusehat_service.dart) | OAuth2 token cache, verifikasi koneksi `Organization`, Master Wilayah (`/masterdata/v1`), validasi, builder FHIR R4 `Patient`, `GET` & `POST /Patient`, serta persistensi via `UserService`. |
| Model User & Admin | [`lib/models/user_profile.dart`](../lib/models/user_profile.dart), [`lib/models/admin_user_model.dart`](../lib/models/admin_user_model.dart) | Menyimpan `nik`, `ihsNumber`, status sinkronisasi, dan kode wilayah Kemendagri (provinsi, kota/kab, kecamatan, kelurahan, kode pos). |
| Layer Persistensi & Rules | [`lib/services/user_service.dart`](../lib/services/user_service.dart), [`firestore.rules`](../firestore.rules) | Membaca/menyimpan data SATUSEHAT pasien di `users/{uid}` (dan `provisioned_accounts`) dengan izin update owner yang diperbarui di Security Rules. |
| Halaman Integrasi SATUSEHAT | [`lib/pages/common/satusehat_patient_sync_page.dart`](../lib/pages/common/satusehat_patient_sync_page.dart) | UI tes koneksi Sandbox, cek NIK, dropdown wilayah bertingkat dari Masterdata SATUSEHAT, preview JSON FHIR R4, dan kirim data pasien. |
| Titik Masuk UI | [`profil_pengguna_page.dart`](../lib/pages/pengguna/profil_pengguna_page.dart), [`edit_profil_pengguna_page.dart`](../lib/pages/pengguna/edit_profil_pengguna_page.dart), [`detail_pengguna_page.dart`](../lib/pages/admin/detail_pengguna_page.dart), [`pengaturan_admin_page.dart`](../lib/pages/admin/pengaturan_admin_page.dart) | Pasien & Admin dapat mengedit NIK, memantau IHS Number, dan mengirim data pasien ke SATUSEHAT. |

---

## 2. Endpoint Sandbox yang Diverifikasi

- **OAuth2 Token (`client_credentials`)**
  - `POST https://api-satusehat-stg.dto.kemkes.go.id/oauth2/v1/accesstoken?grant_type=client_credentials`
  - `Content-Type: application/x-www-form-urlencoded`
- **Verifikasi Organisasi**
  - `GET https://api-satusehat-stg.dto.kemkes.go.id/fhir-r4/v1/Organization/{organizationId}`
- **Master Wilayah Administratif**
  - `GET https://api-satusehat-stg.dto.kemkes.go.id/masterdata/v1/provinces`
  - `GET https://api-satusehat-stg.dto.kemkes.go.id/masterdata/v1/cities?province_codes={code}`
  - `GET https://api-satusehat-stg.dto.kemkes.go.id/masterdata/v1/districts?city_codes={code}`
  - `GET https://api-satusehat-stg.dto.kemkes.go.id/masterdata/v1/sub-districts?district_codes={code}`
- **Patient FHIR R4**
  - Pencarian NIK: `GET https://api-satusehat-stg.dto.kemkes.go.id/fhir-r4/v1/Patient?identifier=https://fhir.kemkes.go.id/id/nik|{nik}`
  - Pencarian Demografi: `GET https://api-satusehat-stg.dto.kemkes.go.id/fhir-r4/v1/Patient?name=...&birthdate=...&gender=...`
  - Ambil per IHS Number: `GET https://api-satusehat-stg.dto.kemkes.go.id/fhir-r4/v1/Patient/{ihsNumber}`
  - Registrasi Pasien Baru: `POST https://api-satusehat-stg.dto.kemkes.go.id/fhir-r4/v1/Patient`

---

## 3. Aturan Validasi & Alur Sinkronisasi Pasien

Berdasarkan pengujian langsung ke server Sandbox SATUSEHAT:
1. `POST /Patient` **mewajibkan** ekstensi kode wilayah administratif Kemendagri 4 tingkat (`province`, `city`, `district`, `village`) pada `address[0].extension` dengan URL `https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode`.
2. Alur `SatuSehatService.syncPatient` bersifat **idempoten**:
   - Memvalidasi NIK (16 digit), nama, tanggal lahir (`YYYY-MM-DD`), jenis kelamin (`Laki-laki` → `male`, `Perempuan` → `female`), telepon, alamat, dan 4 kode wilayah.
   - Mengecek `GET /Patient?identifier=https://fhir.kemkes.go.id/id/nik|{nik}` terlebih dahulu.
   - Jika ditemukan (`total > 0`), langsung mengembalikan IHS Number (`action: 'matched'`).
   - Jika belum terdaftar, mengirim `POST /Patient` (`201 Created`) untuk mendaftarkan pasien dan memperoleh **IHS Number** (`action: 'created'`).
   - Jika `POST /Patient` mengembalikan HTTP `400` dengan body resource `Patient` yang sudah ada, IHS Number tetap diekstrak secara aman (`action: 'matched'`).

---

## 4. Konfigurasi `--dart-define` & Catatan Production

Secara default aplikasi berjalan dalam mode **Sandbox** dengan kredensial staging yang dikonfigurasi di `SatuSehatConfig`. Anda dapat menimpa kredensial saat build/run:

```bash
flutter run \
  --dart-define=SATUSEHAT_ENV=sandbox \
  --dart-define=SATUSEHAT_ORG_ID=... \
  --dart-define=SATUSEHAT_CLIENT_ID=... \
  --dart-define=SATUSEHAT_CLIENT_SECRET=...
```

> **Catatan Keamanan Production:** Saat berpindah ke mode `production`, **jangan** menyimpan `Client Secret` di dalam aplikasi mobile (client-side). Gunakan backend proxy (mis. Cloud Functions / server tersendiri) untuk pertukaran token OAuth2 dan penerusan request FHIR ke SATUSEHAT.
