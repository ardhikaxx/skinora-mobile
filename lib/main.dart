import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/admin/admin_main_page.dart';
import 'pages/admin/notifikasi_admin_page.dart';
import 'pages/admin/master_spesialisasi_page.dart';
import 'pages/admin/tambah_spesialisasi_page.dart';
import 'pages/admin/edit_spesialisasi_page.dart';
import 'pages/admin/manajemen_dokter_page.dart';
import 'pages/admin/tambah_dokter_page.dart';
import 'pages/admin/detail_dokter_page.dart';
import 'pages/admin/manajemen_pengguna_page.dart';
import 'pages/admin/tambah_pengguna_page.dart';
import 'pages/admin/detail_pengguna_page.dart';
import 'pages/admin/profil_admin_page.dart';
import 'pages/admin/edit_profil_admin_page.dart';
import 'pages/admin/pengaturan_admin_page.dart';
import 'pages/admin/tentang_admin_page.dart';
import 'pages/admin/riwayat_aktivitas_admin_page.dart';
import 'pages/admin/manajemen_edukasi_page.dart';
import 'pages/admin/tambah_artikel_page.dart';
import 'pages/admin/edit_artikel_page.dart';
import 'pages/admin/laporan_riwayat_page.dart';
import 'models/admin_article_model.dart';
import 'models/admin_doctor_model.dart';
import 'models/admin_user_model.dart';
import 'pages/dokter/dokter_main_page.dart';
import 'pages/dokter/patient_insight_page.dart';
import 'pages/dokter/notifikasi_dokter_page.dart';
import 'pages/dokter/pengaturan_dokter_page.dart';
import 'pages/pengguna/pengguna_main_page.dart';
import 'pages/pengguna/notifikasi_pengguna_page.dart';
import 'pages/pengguna/konsultasi_dokter_page.dart';
import 'pages/pengguna/edukasi_kulit_page.dart';
import 'pages/pengguna/detail_edukasi_page.dart';
import 'pages/pengguna/skin_check_question1_page.dart';
import 'pages/pengguna/skin_check_question2_page.dart';
import 'pages/pengguna/skin_check_question3_page.dart';
import 'pages/pengguna/skin_check_question4_page.dart';
import 'pages/pengguna/skin_check_question5_page.dart';
import 'pages/pengguna/skin_check_question6_page.dart';
import 'pages/pengguna/skin_check_question7_page.dart';
import 'pages/pengguna/skin_check_result_page.dart';
import 'pages/pengguna/riwayat_skin_check_page.dart';
import 'pages/pengguna/riwayat_konsultasi_page.dart';
import 'pages/pengguna/profil_dokter_page.dart';
import 'pages/pengguna/ruang_konsultasi_page.dart';
import 'pages/pengguna/riwayat_ruang_konsultasi_page.dart';
import 'pages/pengguna/profil_pengguna_page.dart';
import 'pages/pengguna/edit_profil_pengguna_page.dart';
import 'pages/pengguna/pengaturan_pengguna_page.dart';
import 'pages/pengguna/tentang_pengguna_page.dart';
import 'pages/pengguna/skin_daily_page.dart';
import 'pages/pengguna/riwayat_skin_daily_page.dart';
import 'pages/pengguna/insight_kulit_pengguna_page.dart';
import 'pages/pengguna/skincare_page.dart';
import 'pages/pengguna/riwayat_skincare_page.dart';
import 'pages/pengguna/riwayat_aktivitas_pengguna_page.dart';

void main() {
  runApp(const SkinoraApp());
}

class SkinoraApp extends StatelessWidget {
  const SkinoraApp({super.key});

  static const Color brandColor = Color(0xFFB23A48);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skinora App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          primary: brandColor,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFCFCFD),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF321417),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF321417),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin': (context) => const AdminMainPage(),
        '/admin/notifikasi': (context) => const NotifikasiAdminPage(),
        '/admin/spesialisasi': (context) => const MasterSpesialisasiPage(),
        '/admin/spesialisasi/tambah': (context) => const TambahSpesialisasiPage(),
        '/admin/spesialisasi/edit': (context) => const EditSpesialisasiPage(initialName: 'Jerawat'),
        '/admin/dokter': (context) => const ManajemenDokterPage(showBottomNav: true),
        '/admin/dokter/tambah': (context) => const TambahDokterPage(),
        '/admin/dokter/detail': (context) => DetailDokterPage(
              doctor: AdminDoctorModel(
                id: '1',
                name: 'dr. Anita Dewi, Sp.KK',
                email: 'anita@demo.com',
                phone: '081234567800',
                specialization: 'Estetika Kulit',
                experience: '8 tahun',
                str: 'STR-2018-12345',
                bio:
                    'Dokter spesialis kulit dan kelamin dengan pengalaman 8 tahun di bidang estetika kulit. Lulusan Fakultas Kedokteran Universitas Indonesia.',
                status: DoctorStatus.terverifikasi,
              ),
            ),
        '/admin/pengguna': (context) => const ManajemenPenggunaPage(showBottomNav: true),
        '/admin/pengguna/tambah': (context) => const TambahPenggunaPage(),
        '/admin/pengguna/detail': (context) => DetailPenggunaPage(
              user: AdminUserModel(
                id: '1',
                name: 'Leonita Yulyta Agustin',
                email: 'leonita@demo.com',
                phone: '081234567890',
                address: 'Jl. Sudirman No. 123, Jakarta',
                birthDate: '1995-06-15',
                gender: 'Perempuan',
                status: UserStatus.aktif,
              ),
            ),
        '/admin/profil': (context) => const ProfilAdminPage(),
        '/admin/edit-profil': (context) => const EditProfilAdminPage(),
        '/admin/pengaturan': (context) => const PengaturanAdminPage(),
        '/admin/tentang': (context) => const TentangAdminPage(),
        '/admin/riwayat-aktivitas': (context) => const RiwayatAktivitasAdminPage(),
        '/admin/edukasi': (context) => const ManajemenEdukasiPage(showBottomNav: true),
        '/admin/edukasi/tambah': (context) => const TambahArtikelPage(),
        '/admin/edukasi/edit': (context) => EditArtikelPage(
              article: AdminArticleModel(
                id: '1',
                title: 'Mengenal Tipe Kulit Wajah Anda',
                category: 'Kulit Dasar',
                date: '2026-08-01',
                content:
                    'Pelajari cara mengenali tipe kulit wajah Anda untuk perawatan yang lebih tepat.',
                status: ArticleStatus.diterbitkan,
              ),
            ),
        '/admin/laporan': (context) => const LaporanRiwayatPage(),
        '/dokter': (context) => const DokterMainPage(),
        '/dokter/patient-insight': (context) => const PatientInsightPage(),
        '/dokter/notifikasi': (context) => const NotifikasiDokterPage(),
        '/dokter/pengaturan': (context) => const PengaturanDokterPage(),
        '/pengguna': (context) => const PenggunaMainPage(),
        '/pengguna/notifikasi': (context) => const NotifikasiPenggunaPage(),
        '/pengguna/konsultasi': (context) => const KonsultasiDokterPenggunaPage(),
        '/pengguna/profil-dokter': (context) => const ProfilDokterPenggunaPage(),
        '/pengguna/ruang-konsultasi': (context) => const RuangKonsultasiPenggunaPage(),
        '/pengguna/riwayat-ruang-konsultasi': (context) => const RiwayatRuangKonsultasiPage(),
        '/pengguna/riwayat-konsultasi': (context) => const RiwayatKonsultasiPenggunaPage(),
        '/pengguna/edukasi': (context) => const EdukasiKulitPenggunaPage(),
        '/pengguna/detail-edukasi': (context) => const DetailEdukasiPenggunaPage(),
        '/pengguna/skin-check/pertanyaan-1': (context) => const SkinCheckQuestion1Page(),
        '/pengguna/skin-check/pertanyaan-2': (context) => const SkinCheckQuestion2Page(age: '20'),
        '/pengguna/skin-check/pertanyaan-3': (context) => const SkinCheckQuestion3Page(age: '20', gender: 'Perempuan'),
        '/pengguna/skin-check/pertanyaan-4': (context) => const SkinCheckQuestion4Page(age: '20', gender: 'Perempuan', conditionAfterWash: 'Terasa cukup nyaman'),
        '/pengguna/skin-check/pertanyaan-5': (context) => const SkinCheckQuestion5Page(age: '20', gender: 'Perempuan', conditionAfterWash: 'Terasa cukup nyaman', oilCondition: 'Sedikit berminyak, terutama di area tertentu'),
        '/pengguna/skin-check/pertanyaan-6': (context) => const SkinCheckQuestion6Page(age: '20', gender: 'Perempuan', conditionAfterWash: 'Terasa cukup nyaman', oilCondition: 'Sedikit berminyak, terutama di area tertentu', sensitivity: 'Kadang mengalami kemerahan atau iritasi'),
        '/pengguna/skin-check/pertanyaan-7': (context) => const SkinCheckQuestion7Page(age: '20', gender: 'Perempuan', conditionAfterWash: 'Terasa cukup nyaman', oilCondition: 'Sedikit berminyak, terutama di area tertentu', sensitivity: 'Kadang mengalami kemerahan atau iritasi', humidity: '74%'),
        '/pengguna/skin-check/hasil': (context) => const SkinCheckResultPage(),
        '/pengguna/skin-check/riwayat': (context) => const RiwayatSkinCheckPage(),
        '/pengguna/edit-profil': (context) => const EditProfilPenggunaPage(),
        '/pengguna/pengaturan': (context) => const PengaturanPenggunaPage(),
        '/pengguna/tentang': (context) => const TentangPenggunaPage(),
        '/pengguna/riwayat-aktivitas': (context) => const RiwayatAktivitasPenggunaPage(),
        '/pengguna/profil': (context) => const ProfilPenggunaPage(showBottomNav: true),
        '/pengguna/skin-daily': (context) => const SkinDailyPage(showBottomNav: true),
        '/pengguna/skin-daily/riwayat': (context) => const RiwayatSkinDailyPage(showBottomNav: true),
        '/pengguna/skin-daily/insight': (context) => const InsightKulitPenggunaPage(showBottomNav: true),
        '/pengguna/skincare': (context) => const SkincarePage(showBottomNav: true),
        '/pengguna/skincare/riwayat': (context) => const RiwayatSkincarePage(showBottomNav: true),
      },
    );
  }
}
