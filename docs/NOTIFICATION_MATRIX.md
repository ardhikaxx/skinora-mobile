# Matriks Notifikasi Skinora

Satu file acuan untuk seluruh event notifikasi: **siapa yang menulis dokumen**,
**siapa yang menerima**, dan **ke mana user dibawa** saat mengetuk.

Aturan dasar:

- **Penyimpanan per user.** Setiap notifikasi berada di
  `users/{recipientUid}/notifications/{notificationId}` — tidak ada koleksi
  global, sehingga rules cukup memvalidasi kolom `{uid}` path terhadap
  `request.auth.uid`. Halaman Notifikasi & badge ketiga role membaca
  subcollection miliknya sendiri.
- **Ditulis client.** Tidak ada Cloud Functions (project tetap di Spark/free
  tier). Actor yang melakukan bisnis operasi (booking, chat, verifikasi, jadwal)
  menulis notifikasi penerimanya sendiri dengan `createdBy == request.auth.uid`.
- **Satu doc ID per event.** `NotificationEventKey.build(type, recipient, entity)`
  → `{type}__{recipient}__{entity}` sehingga retry/fan-out tidak pernah
  menghasilkan dokumen ganda.
- **Anti-spam.** `SeenCache` menjamin satu `notificationId` hanya ditampilkan
  sekali walau datang dari dua jalur. Pesan chat di ruang yang sedang dibuka
  (`ActiveChatRegistry`) tidak menampilkan native notification, tetapi tetap
  tersimpan di Firestore.
- **Privasi chat.** Notifikasi chat tidak pernah membawa isi pesan — hanya
  pemberitahuan generik.

### Presentasi native vs sumber data

| Kondisi | Jalur | Catatan |
| --- | --- | --- |
| Foreground | `FirebaseMessaging.onMessage` + stream Firestore `users/{uid}/notifications` → `flutter_local_notifications` | satu native notification, tanpa duplikat |
| Background / terminated / layar mati | **Belum ada pengirim FCM** (lihat "Status dispatcher" di bawah) | payload data-only + token device sudah disiapkan, tinggal butuh penerima |
| Pengingat pagi/malam | `flutter_local_notifications` + `timezone` (jadwal lokal, selamat dari reboot) | tidak bergantung aplikasi terbuka |

## Siapa menulis dokumen

| Tulisan | Pelaku | Alasan |
| --- | --- | --- |
| Booking, konsultasi dimulai/selesai, pesan chat, verifikasi/tolak/tangguh/aktifkan dokter, tangguh/aktifkan pengguna, tambah/hapus/ubah jadwal | **Client** | Actor (pasien/dokter/admin) sudah login dan diizinkan Security Rules (`createdBy == request.auth.uid` + `recipientUid == {uid}` path, sah lewat `care_link` atau `isAdmin()`). |
| `doctor_verification_pending` | **Client admin** (sinkron saat login admin) | Dokter yang mendaftar tidak boleh menulis notifikasi ke koleksi admin; admin menemukan sendiri daftar `role=dokter, status=menunggu`. |
| `article_published` | **Client admin** (fan-out saat artikel diterbitkan) | Admin menulis ke subcollection tiap pengguna, diizinkan `isAdmin()`. |

> Fan-out client hanya berjalan saat aplikasi aktif. Bila ada layanan
> pelengkap nanti, cukup tambahkan pengirim FCM data-only yang membaca
> `users/{uid}/notifications` — tidak ada perubahan struktur dokumen.

## Matriks event

| # | Type | Penerima | Penulis | Judul (contoh) | Deep-link |
| --- | --- | --- | --- | --- | --- |
| 1 | `booking_created` | Dokter tujuan | Client — `ConsultationService.book` | Booking Baru | shell Dokter → tab **Jadwal** |
| 2 | `booking_created` | Pasien | Client — `ConsultationService.book` | Booking Berhasil | page `/pengguna/riwayat-konsultasi` |
| 3 | `booking_created` | Semua admin | Client — `ConsultationService.book` → `notifyAdmins` | Konsultasi Baru | shell Admin → tab **Beranda** |
| 4 | `booking_confirmed` | Pasien | — (reserved, belum ada aksi konfirmasi) | Booking Dikonfirmasi | page `/pengguna/riwayat-konsultasi` |
| 5 | `booking_cancelled` | Pasien + dokter | — (reserved, belum ada aksi pembatalan) | Booking Dibatalkan | riwayat / tab Jadwal |
| 6 | `consultation_started` | Pasien | Client — `ConsultationService.markBerlangsung` | Konsultasi Dimulai | **room** ruang konsultasi (`entityId`) |
| 7 | `consultation_message` | Lawan bicara | Client — `ConsultationService.sendMessage` | Pesan Baru | **room** ruang chat/konsultasi (`entityId`) |
| 8 | `consultation_completed` | Pasien | Client — `ConsultationService.complete` | Konsultasi Selesai | page `/pengguna/riwayat-konsultasi` |
| 9 | `consultation_completed` | Dokter | Client — `ConsultationService.complete` | Konsultasi Selesai | page `/dokter/riwayat` |
| 10 | `doctor_verification_pending` | Semua admin | Client admin — `NotificationService._syncPendingDoctorVerifications` (saat login admin) | Dokter Menunggu Verifikasi | shell Admin → tab **Dokter** |
| 11 | `doctor_verified` | Dokter | Client — `DetailDokterPage._persistStatus` | Akun Terverifikasi | shell Dokter → tab **Profil** |
| 12 | `doctor_rejected` | Dokter | Client — `DetailDokterPage._persistStatus` | Verifikasi Ditolak | shell Dokter → tab **Profil** |
| 13 | `doctor_suspended` | Dokter | Client — `DetailDokterPage._persistStatus` | Akun Ditangguhkan | shell Dokter → tab **Profil** |
| 14 | `doctor_reactivated` | Dokter | Client — `DetailDokterPage._persistStatus` | Akun Diaktifkan Kembali | shell Dokter → tab **Profil** |
| 15 | `patient_suspended` | Pengguna | Client — `DetailPenggunaPage._persistStatus` | Akun Ditangguhkan | shell Pengguna → tab **Profil** |
| 16 | `patient_reactivated` | Pengguna | Client — `DetailPenggunaPage._persistStatus` | Akun Diaktifkan Kembali | shell Pengguna → tab **Profil** |
| 17 | `article_published` | Semua pengguna | Client admin — `ArticleService._announcePublished` (setelah artikel tersimpan) | Artikel Baru | page `/pengguna/edukasi` |
| 18 | `schedule_created` | Dokter (diri sendiri) | Client — `ScheduleService.addSlot` | Jadwal Ditambahkan | shell Dokter → tab **Jadwal** |
| 19 | `schedule_cancelled` | Dokter (diri sendiri) | Client — `ScheduleService.deleteSlot` | Jadwal Dihapus | shell Dokter → tab **Jadwal** |
| 20 | `schedule_changed` | Dokter (diri sendiri) | Client — `ScheduleService.setAvailability` | Praktik Dibuka/Ditutup | shell Dokter → tab **Jadwal** |
| 21 | `reminder` | Diri sendiri | Lokal (`ReminderScheduler`, tanpa Firestore) | Pengingat Pagi/Malam | shell Pengguna → tab **Beranda** |
| 22 | `system` | Kontekstual | Manual | Info Skinora | fallback beranda role |

`booking_confirmed` dan `booking_cancelled` masih **reserved**: aplikasi belum
punya aksi konfirmasi/batal konsultasi (aturan `consultations.update` hanya
mengizinkan dokter/admin, tidak ada tombolnya). Begitu fiturnya ada, cukup
panggil `NotificationService.notifyUser(..., type: NotificationType.bookingCancelled)`
— type, channel (`skinora_booking`) dan deep-link riwayat sudah siap.

## Audience & Security Rules

- Notifikasi disimpan di **`users/{recipientUid}/notifications/{id}`** — tidak
  ada koleksi global. Rules hanya mengizinkan `read` pemilik (`isOwner`) atau
  admin.
- `create` mensyaratkan `recipientUid == {uid}` (kolom path) dan
  `createdBy == request.auth.uid`, lalu salah satu dari: pemilik, admin, atau
  pasangan `care_links` (pasien ↔ dokter). Artinya user **tidak** bisa menulis
  ke koleksi orang lain kecuali memang terhubung lewat booking.
- Field `audience = user:{uid}` tetap disimpan sebagai metadata; `role:admin`
  tidak lagi ditulis (fan-out admin memakai uid per admin).
- `update` hanya mengenai `isUnread` / `isRead` / `readAt` — tombol "tandai
  sudah dibaca"; isi notifikasi terkunci oleh `hasOnly`.

## Status dispatcher (FCM)

| Komponen | Status |
| --- | --- |
| Token device `users/{uid}/devices/{deviceId}`, `onTokenRefresh`, nonaktif saat logout | ✅ siap |
| Payload data-only + handler `skinoraBackgroundMessageHandler` | ✅ siap |
| Pengirim FCM dari server | ❌ **belum ada** — Cloud Functions butuh plan Blaze, dan keputusan saat ini memakai jalur gratis tanpa server |

Konsekuensi: **ketika aplikasi berjalan** (foreground / Android masih hidup di
background), stream Firestore `users/{uid}/notifications` memicu
`flutter_local_notifications` sehingga notifikasi native tetap muncul.
**Ketika aplikasi force-stopped atau di-background panjang**, native
notification tidak muncul sampai ada pengirim FCM — dokumennya tetap tersimpan
dan badge/daftar langsung lengkap saat aplikasi dibuka.

Untuk mengaktifkan push penuh tanpa mengubah struktur: tulis satu layanan
kecil (mis. Cloudflare Worker gratis, atau Cloud Functions setelah plan Blaze
aktif) yang membaca `users/{uid}/notifications` dan mengirim FCM data-only ke
`DeviceTokenService.activeTokens(uid)`.

## Perangkat (`users/{uid}/devices/{deviceId}`)

Ditulis oleh `DeviceTokenService` (upsert saat login, refresh token, dan
nonaktif saat logout). Logout menandai `isActive = false` untuk perangkat
tersebut saja, sehingga user berikutnya yang login pada perangkat yang sama
mendaftarkan token miliknya sendiri.

## Kanal & prioritas

| Kanal | Importance | Type |
| --- | --- | --- |
| `skinora_booking` | high | `booking_created`, `booking_confirmed`, `booking_cancelled` |
| `skinora_consultation` | high | `consultation_started`, `consultation_message` |
| `skinora_general` | default | sisanya |
| `skinora_system` | default | `system`, `doctor_verification_pending`, `article_published` |
| `skinora_reminder` | default | `reminder` |

## Preferensi

`users/{uid}.settings`:

- `notificationsEnabled` — mematikan push + pengingat (juga dipersist lokal
  sehingga isolate background FCM menghormatinya).
- `morningReminder` / `eveningReminder` — `HH:mm`, dijadwalkan ulang oleh
  `ReminderScheduler.sync` setiap kali pengaturan disimpan.

## Deploy

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

> `firebase deploy --only functions` tidak dipakai (tidak ada Cloud Functions;
> dispatcher FCM masih menyusul — lihat "Status dispatcher").
