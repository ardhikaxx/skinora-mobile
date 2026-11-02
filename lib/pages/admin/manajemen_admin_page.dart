import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/empty_state.dart';
import '../../models/admin_account_model.dart';
import '../../models/admin_user_model.dart';
import '../../services/auth_service.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';
import 'detail_admin_page.dart';
import 'tambah_admin_page.dart';

class ManajemenAdminPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final List<AdminAccountModel>? initialAdmins;

  const ManajemenAdminPage({
    super.key,
    this.onNavigateTab,
    this.initialAdmins,
  });

  @override
  State<ManajemenAdminPage> createState() => _ManajemenAdminPageState();
}

class _ManajemenAdminPageState extends State<ManajemenAdminPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<AdminAccountModel> _admins;
  StreamSubscription<List<AdminAccountModel>>? _adminSub;

  @override
  void initState() {
    super.initState();
    _admins = widget.initialAdmins != null
        ? List.from(widget.initialAdmins!)
        : <AdminAccountModel>[];
    _loadFromBackend();
  }

  /// Ambil data admin dari Firestore secara realtime.
  void _loadFromBackend() {
    if (widget.initialAdmins != null) return;
    if (!Backend.useFirebase) return;
    _adminSub?.cancel();
    _adminSub = UserService.streamAdmin().listen(
      (admins) {
        if (!mounted) return;
        setState(() => _admins
          ..clear()
          ..addAll(admins));
      },
      onError: (_) {
        if (!mounted) return;
        setState(_admins.clear);
      },
    );
  }

  @override
  void dispose() {
    _adminSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<AdminAccountModel> get _filteredAdmins {
    if (_searchQuery.isEmpty) {
      return _admins;
    }
    final q = _searchQuery.toLowerCase();
    return _admins.where((admin) {
      return admin.name.toLowerCase().contains(q) ||
          admin.email.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildEmptyState() {
    if (_admins.isEmpty) {
      return EmptyStateWidget(
        icon: LucideIcons.shieldCheck,
        title: 'Belum ada data admin',
        description: 'Akun administrator Skinora akan ditampilkan di sini.',
        actionLabel: 'Tambah Admin',
        onAction: _navigateToAddAdmin,
      );
    }
    return NoSearchResultWidget(
      title: 'Admin tidak ditemukan',
      description:
          'Tidak ada admin yang cocok dengan "$_searchQuery". Coba kata kunci lain.',
      onAction: () => setState(() {
        _searchController.clear();
        _searchQuery = '';
      }),
    );
  }

  Future<void> _navigateToAddAdmin() async {
    final result = await Navigator.push<AdminAccountModel>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahAdminPage(
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _admins.insert(0, result);
      });
      AdminSuccessDialog.show(
        context,
        message: 'Admin baru berhasil ditambahkan',
      );
    }
  }

  Future<void> _navigateToAdminDetail(AdminAccountModel admin) async {
    final previousStatus = admin.status;
    final result = await Navigator.push<AdminAccountModel>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailAdminPage(
          admin: admin,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final index = _admins.indexWhere((a) => a.id == result.id);
        if (index != -1) {
          _admins[index] = result;
        }
      });

      if (previousStatus != result.status) {
        if (result.status == UserStatus.ditangguhkan) {
          AdminSuccessDialog.show(
            context,
            message: '${result.name} telah ditangguhkan',
          );
        } else if (result.status == UserStatus.aktif) {
          AdminSuccessDialog.show(
            context,
            message: '${result.name} telah diaktifkan kembali',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Chevron Left (if can pop) + Title
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 20.0,
                top: 16.0,
                bottom: 12.0,
              ),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    IconButton(
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: darkText,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Expanded(
                    child: Text(
                      'Manajemen Admin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar + "+ Baru" Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkText,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari nama atau email admin...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF9CA3AF),
                          ),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // "+ Baru" Button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _navigateToAddAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Baru',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Admins List
            Expanded(
              child: _filteredAdmins.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _filteredAdmins.length,
                      itemBuilder: (context, index) {
                        final admin = _filteredAdmins[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildAdminCard(admin),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(AdminAccountModel admin) {
    final isSelf = Backend.useFirebase &&
        admin.registered &&
        admin.backendId == AuthService.uid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAdminDetail(admin),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Avatar initial circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: primaryMaroon,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      admin.initials,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              admin.name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF86EFAC),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'Anda',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        admin.email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status badges
                if (!admin.registered) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Undangan',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ] else if (admin.status == UserStatus.ditangguhkan) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBD8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Ditangguhkan',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
