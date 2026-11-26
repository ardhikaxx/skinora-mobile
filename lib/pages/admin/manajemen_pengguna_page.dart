import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/empty_state.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_user_model.dart';
import '../../services/backend.dart';
import '../../services/user_service.dart';
import 'detail_pengguna_page.dart';
import 'tambah_pengguna_page.dart';

class ManajemenPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ManajemenPenggunaPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
    this.initialUsers,
  });

  final List<AdminUserModel>? initialUsers;

  @override
  State<ManajemenPenggunaPage> createState() => _ManajemenPenggunaPageState();
}

class _ManajemenPenggunaPageState extends State<ManajemenPenggunaPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSatuSehatFilter = 'Semua';

  static const List<String> _satuSehatFilters = [
    'Semua',
    'Terintegrasi SATUSEHAT',
    'Belum SATUSEHAT',
  ];

  late final List<AdminUserModel> _users;

  StreamSubscription<List<AdminUserModel>>? _userSub;

  @override
  void initState() {
    super.initState();
    _users = widget.initialUsers != null
        ? List.from(widget.initialUsers!)
        : <AdminUserModel>[];
    _loadFromBackend();
  }

  /// Ambil data pengguna dari Firestore secara realtime.
  void _loadFromBackend() {
    if (widget.initialUsers != null) return;
    if (!Backend.useFirebase) return;
    _userSub?.cancel();
    _userSub = UserService.streamPengguna().listen(
      (users) {
        if (!mounted) return;
        setState(() => _users
          ..clear()
          ..addAll(users));
      },
      onError: (_) {
        if (!mounted) return;
        setState(_users.clear);
      },
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _isIntegratedSatuSehat(AdminUserModel user) {
    return user.ihsNumber.trim().isNotEmpty ||
        user.satuSehatStatus.trim().toLowerCase() == 'terhubung';
  }

  int get _integratedCount => _users.where(_isIntegratedSatuSehat).length;

  int get _unintegratedCount =>
      _users.where((u) => !_isIntegratedSatuSehat(u)).length;

  List<AdminUserModel> get _filteredUsers {
    Iterable<AdminUserModel> result = _users;

    if (_selectedSatuSehatFilter == 'Terintegrasi SATUSEHAT') {
      result = result.where(_isIntegratedSatuSehat);
    } else if (_selectedSatuSehatFilter == 'Belum SATUSEHAT') {
      result = result.where((u) => !_isIntegratedSatuSehat(u));
    }

    if (_searchQuery.isEmpty) {
      return result.toList();
    }
    final q = _searchQuery.toLowerCase();
    return result.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q) ||
          user.nik.toLowerCase().contains(q) ||
          user.ihsNumber.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildUsersEmptyState() {
    if (_users.isEmpty) {
      return EmptyStateWidget(
        icon: LucideIcons.users,
        title: 'Belum ada data pengguna',
        description: 'Akun pengguna Skinora yang terdaftar akan muncul di sini.',
        actionLabel: 'Tambah Pengguna',
        onAction: _navigateToAddUser,
      );
    }
    if (_selectedSatuSehatFilter != 'Semua' && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        icon: LucideIcons.heartPulse,
        title: 'Belum ada pasien pada filter ini',
        description: _selectedSatuSehatFilter == 'Terintegrasi SATUSEHAT'
            ? 'Belum ada pasien yang tersinkronisasi ke SATUSEHAT.'
            : 'Semua pasien sudah terintegrasi ke SATUSEHAT.',
        actionLabel: 'Tampilkan Semua',
        onAction: () => setState(() {
          _selectedSatuSehatFilter = 'Semua';
        }),
      );
    }
    return NoSearchResultWidget(
      title: 'Pengguna tidak ditemukan',
      description:
          'Tidak ada pengguna yang cocok dengan "$_searchQuery". Coba ubah kata kunci.',
      onAction: () => setState(() {
        _searchController.clear();
        _searchQuery = '';
      }),
    );
  }

  Future<void> _navigateToAddUser() async {
    final result = await Navigator.push<AdminUserModel>(
      context,
      MaterialPageRoute(
        builder: (context) => TambahPenggunaPage(
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _users.insert(0, result);
      });
      AdminSuccessDialog.show(
        context,
        message: 'Pengguna baru berhasil ditambahkan',
      );
    }
  }

  Future<void> _navigateToUserDetail(AdminUserModel user) async {
    final previousStatus = user.status;
    final result = await Navigator.push<AdminUserModel>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPenggunaPage(
          user: user,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        final index = _users.indexWhere((u) => u.id == result.id);
        if (index != -1) {
          _users[index] = result;
        }
      });

      // Show success dialog matching Screen 5 if status changed to suspended
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

  String _getAvatarInitial(AdminUserModel user) {
    return user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title
            const Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: 12.0,
              ),
              child: Text(
                'Manajemen Pengguna',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  letterSpacing: -0.3,
                ),
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
                          hintText: 'Cari pengguna...',
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
                      onPressed: _navigateToAddUser,
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

            const SizedBox(height: 14),

            // Horizontal Filter Chips (Status Integrasi SATUSEHAT)
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                scrollDirection: Axis.horizontal,
                itemCount: _satuSehatFilters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _satuSehatFilters[index];
                  final isSelected = _selectedSatuSehatFilter == filter;
                  final count = switch (filter) {
                    'Terintegrasi SATUSEHAT' => _integratedCount,
                    'Belum SATUSEHAT' => _unintegratedCount,
                    _ => _users.length,
                  };

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSatuSehatFilter = filter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryMaroon : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryMaroon
                              : const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$filter ($count)',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Users List
            Expanded(
              child: _filteredUsers.isEmpty
                  ? _buildUsersEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildUserCard(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AdminNavBottom(
              currentIndex: 2,
              onTap: (index) {
                if (index != 2) {
                  widget.onNavigateTab?.call(index);
                }
              },
            )
          : null,
    );
  }

  /// User list card matching Screen 1 & Screen 6
  Widget _buildUserCard(AdminUserModel user) {
    final initialLetter = _getAvatarInitial(user);

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
          onTap: () => _navigateToUserDetail(user),
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
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // User Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: subText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isIntegratedSatuSehat(user)) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.circleCheck,
                                    size: 11,
                                    color: Color(0xFF15803D),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.ihsNumber.trim().isNotEmpty
                                        ? 'SATUSEHAT • ${user.ihsNumber.trim()}'
                                        : 'SATUSEHAT',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status Badge if suspended (Screen 5 & 6)
                if (user.status == UserStatus.ditangguhkan) ...[
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
