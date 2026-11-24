import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinora_app/models/admin_account_model.dart';
import 'package:skinora_app/models/admin_article_model.dart';
import 'package:skinora_app/models/admin_user_model.dart';
import 'package:skinora_app/pages/admin/detail_admin_page.dart';
import 'package:skinora_app/pages/admin/manajemen_admin_page.dart';
import 'package:skinora_app/pages/admin/manajemen_edukasi_page.dart';
import 'package:skinora_app/services/article_service.dart';
import 'package:skinora_app/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Akun Admin A (Admin Utama / Super Admin)
  final adminA = AdminAccountModel(
    id: 'admin_1',
    name: 'Admin Utama (Admin A)',
    email: 'admin.utama@skinora.id',
    phone: '081234567890',
    address: 'Jakarta',
    status: UserStatus.aktif,
    registered: true,
    isSuperAdmin: true,
  );

  // Akun Admin B (Admin Operasional / Admin Biasa)
  final adminB = AdminAccountModel(
    id: 'admin_2',
    name: 'Admin Operasional (Admin B)',
    email: 'ops@skinora.id',
    phone: '089876543210',
    address: 'Bandung',
    status: UserStatus.aktif,
    registered: true,
    createdBy: 'admin_1', // dibuat oleh Admin A
  );

  // Akun Admin C (Akun yang dibuat / diundang oleh Admin B)
  final adminC = AdminAccountModel(
    id: 'admin_3',
    name: 'Admin Junior (Admin C)',
    email: 'junior@skinora.id',
    phone: '081122334455',
    address: 'Surabaya',
    status: UserStatus.aktif,
    registered: false,
    createdBy: 'admin_2', // dibuat oleh Admin B
  );

  // Akun Admin D (Akun yang dibuat oleh Admin A / pihak lain, bukan oleh Admin B)
  final adminD = AdminAccountModel(
    id: 'admin_4',
    name: 'Admin Keuangan (Admin D)',
    email: 'finance@skinora.id',
    phone: '081999888777',
    address: 'Yogyakarta',
    status: UserStatus.aktif,
    registered: true,
    createdBy: 'admin_1',
  );

  group('UserService Controlling canDeleteAdmin & deleteAdmin', () {
    test('Admin B TIDAK BISA menghapus data Admin A (Admin Utama)', () {
      final canDelete = UserService.canDeleteAdmin(
        targetAdmin: adminA,
        actorUid: adminB.id,
        actorEmail: adminB.email,
      );
      expect(canDelete, isFalse);

      expect(
        () => UserService.deleteAdmin(
          adminA,
          actorUid: adminB.id,
          actorEmail: adminB.email,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Akses ditolak'),
          ),
        ),
      );
    });

    test('Admin B TIDAK BISA menghapus data Admin D (bukan dibuat oleh Admin B)', () {
      final canDelete = UserService.canDeleteAdmin(
        targetAdmin: adminD,
        actorUid: adminB.id,
        actorEmail: adminB.email,
      );
      expect(canDelete, isFalse);

      expect(
        () => UserService.deleteAdmin(
          adminD,
          actorUid: adminB.id,
          actorEmail: adminB.email,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Admin B TIDAK BISA menghapus akun dirinya sendiri (self-deletion dicegah)', () {
      final canDelete = UserService.canDeleteAdmin(
        targetAdmin: adminB,
        actorUid: adminB.id,
        actorEmail: adminB.email,
      );
      expect(canDelete, isFalse);
    });

    test('Admin B BISA menghapus Admin C yang dibuat / diundangnya sendiri', () {
      final canDelete = UserService.canDeleteAdmin(
        targetAdmin: adminC,
        actorUid: adminB.id,
        actorEmail: adminB.email,
      );
      expect(canDelete, isTrue);
    });

    test('Admin A (Admin Utama / Super Admin) BISA menghapus admin di bawahnya', () {
      final canDeleteB = UserService.canDeleteAdmin(
        targetAdmin: adminB,
        actorUid: adminA.id,
        actorEmail: adminA.email,
      );
      expect(canDeleteB, isTrue);

      final canDeleteD = UserService.canDeleteAdmin(
        targetAdmin: adminD,
        actorUid: adminA.id,
        actorEmail: adminA.email,
      );
      expect(canDeleteD, isTrue);
    });

    test('Admin Utama (Admin A) TIDAK BISA ditangguhkan oleh admin lain (Admin B)', () {
      expect(
        () => UserService.updateAdminStatus(
          adminA,
          actorUid: adminB.id,
          actorEmail: adminB.email,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('DetailAdminPage UI Controlling (Admin B viewing Admin A)', () {
    testWidgets('Admin B login -> membuka Detail Admin A -> tombol Hapus terkunci dan muncul banner Kontrol Hak Akses',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DetailAdminPage(
            admin: adminA,
            currentAdminId: adminB.id,
            currentAdminEmail: adminB.email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi nama dan info Admin A
      expect(find.text('Admin Utama (Admin A)'), findsOneWidget);
      expect(find.text('admin.utama@skinora.id'), findsWidgets);

      // Verifikasi banner peringatan kontrol hak akses tampil
      expect(find.text('Kontrol Hak Akses'), findsOneWidget);
      expect(
        find.textContaining('Admin lain (Admin B) tidak dapat menghapus data Admin A'),
        findsOneWidget,
      );

      // Verifikasi tombol Hapus Admin dalam status Terkunci
      expect(find.text('Hapus Data Admin (Terkunci)'), findsOneWidget);

      // Tap tombol yang terkunci -> memicu SnackBar Akses Ditolak
      await tester.ensureVisible(find.text('Hapus Data Admin (Terkunci)'));
      await tester.tap(find.text('Hapus Data Admin (Terkunci)'));
      await tester.pump();

      expect(find.textContaining('Akses Ditolak: Anda tidak dapat menghapus data Admin A'), findsOneWidget);
    });

    testWidgets('Admin A login -> membuka Detail Admin B -> tombol Hapus aktif dan memicu konfirmasi',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DetailAdminPage(
            admin: adminB,
            currentAdminId: adminA.id,
            currentAdminEmail: adminA.email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Operasional (Admin B)'), findsOneWidget);

      // Karena Admin A berhak menghapus Admin B, tombol Hapus Data Admin aktif (bukan terkunci)
      expect(find.text('Hapus Data Admin'), findsOneWidget);
      expect(find.text('Hapus Data Admin (Terkunci)'), findsNothing);

      // Tap Hapus Data Admin -> dialog konfirmasi muncul
      await tester.ensureVisible(find.text('Hapus Data Admin'));
      await tester.tap(find.text('Hapus Data Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Data Admin'), findsWidgets);
      expect(find.textContaining('Apakah Anda yakin ingin menghapus data admin'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Batal dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    });

    testWidgets('Admin B login -> membuka Detail Admin B sendiri -> tampil info akun sendiri',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: DetailAdminPage(
            admin: adminB,
            currentAdminId: adminB.id,
            currentAdminEmail: adminB.email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ini adalah akun Anda saat ini. Anda tidak dapat menangguhkan atau menghapus akun Anda sendiri.'),
        findsOneWidget,
      );
      expect(find.text('Hapus Data Admin'), findsNothing);
      expect(find.text('Tangguhkan Admin'), findsNothing);
    });
  });

  group('ManajemenAdminPage Flow with Controlling', () {
    testWidgets('Admin B login -> membuka list admin -> badge Anda tampil di Admin B, klik Admin A membawa ke detail terkunci',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ManajemenAdminPage(
            initialAdmins: [adminA, adminB, adminC],
            currentAdminId: adminB.id,
            currentAdminEmail: adminB.email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge "Anda" tampil pada kartu Admin B
      expect(find.text('Anda'), findsOneWidget);

      // Tap kartu Admin A
      await tester.tap(find.text('Admin Utama (Admin A)'));
      await tester.pumpAndSettle();

      // Halaman detail Admin A terbuka dengan kontrol terkunci
      expect(find.text('Detail Admin'), findsOneWidget);
      expect(find.text('Hapus Data Admin (Terkunci)'), findsOneWidget);
    });
  });

  group('ArticleService & ManajemenEdukasiPage Controlling (Admin B cannot delete Admin A article)', () {
    final articleAdminA = AdminArticleModel(
      id: 'art_1',
      title: 'Perawatan Kulit Sensitif oleh Admin A',
      category: 'Tips Kulit',
      date: '2026-11-20',
      content: 'Panduan lengkap perawatan kulit sensitif.',
      status: ArticleStatus.diterbitkan,
      createdBy: 'admin_1', // Dibuat oleh Admin A
      authorName: 'Admin Utama (Admin A)',
    );

    final articleAdminB = AdminArticleModel(
      id: 'art_2',
      title: 'Tips Hidrasi Kulit oleh Admin B',
      category: 'Gaya Hidup',
      date: '2026-11-21',
      content: 'Pentingnya air untuk kesehatan kulit.',
      status: ArticleStatus.diterbitkan,
      createdBy: 'admin_2', // Dibuat oleh Admin B
      authorName: 'Admin Operasional (Admin B)',
    );

    test('ArticleService: Admin B TIDAK BISA menghapus artikel milik Admin A', () {
      final canDeleteA = ArticleService.canDeleteArticle(
        article: articleAdminA,
        actorUid: adminB.id,
        actorEmail: adminB.email,
      );
      expect(canDeleteA, isFalse);

      expect(
        () => ArticleService.delete(
          articleAdminA.id,
          actorUid: adminB.id,
          actorEmail: adminB.email,
          articleCreatedBy: articleAdminA.createdBy,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('ArticleService: Admin B BISA menghapus artikel miliknya sendiri', () {
      final canDeleteB = ArticleService.canDeleteArticle(
        article: articleAdminB,
        actorUid: adminB.id,
        actorEmail: adminB.email,
      );
      expect(canDeleteB, isTrue);
    });

    testWidgets('ManajemenEdukasiPage: Admin B mencoba menghapus artikel Admin A -> dicegat oleh kontrol akses',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ManajemenEdukasiPage(
            initialArticles: [articleAdminA],
            currentAdminId: adminB.id,
            currentAdminEmail: adminB.email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perawatan Kulit Sensitif oleh Admin A'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      // Admin B menekan tombol Hapus pada artikel Admin A
      await tester.tap(find.text('Hapus'));
      await tester.pump();

      // Dicegat oleh kontrol hak akses dengan SnackBar peringatan
      expect(find.textContaining('Akses Ditolak: Anda tidak dapat menghapus artikel'), findsOneWidget);
    });
  });
}
