import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/dialogs/admin_action_dialogs.dart';
import '../../components/navbottom/admin_navbottom.dart';
import '../../models/admin_user_model.dart';
import 'detail_pengguna_page.dart';
import 'tambah_pengguna_page.dart';

class ManajemenPenggunaPage extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool showBottomNav;

  const ManajemenPenggunaPage({
    super.key,
    this.onNavigateTab,
    this.showBottomNav = false,
  });

  @override
  State<ManajemenPenggunaPage> createState() => _ManajemenPenggunaPageState();
}

class _ManajemenPenggunaPageState extends State<ManajemenPenggunaPage> {
  static const Color primaryMaroon = Color(0xFFA83244);
  static const Color darkText = Color(0xFF1E293B);
  static const Color subText = Color(0xFF6B7280);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<AdminUserModel> _users = [
    AdminUserModel(
      id: '1',
      name: 'Leonita Yulyta Agustin',
      email: 'leonita@demo.com',
      phone: '081234567890',
      address: 'Jl. Sudirman No. 123, Jakarta',
      birthDate: '1995-06-15',
      gender: 'Perempuan',
      status: UserStatus.aktif,
    ),
    AdminUserModel(
      id: '2',
      name: 'Annida Tri Aulia',
      email: 'annida@demo.com',
      phone: '081234567891',
      address: 'Jl. Melati No. 45, Bandung',
      birthDate: '1998-03-22',
      gender: 'Perempuan',
      status: UserStatus.aktif,
    ),
    AdminUserModel(
      id: '3',
      name: 'Kafi Khaula Yukisa Zailina',
      email: 'kafi@demo.com',
      phone: '081234567892',
      address: 'Jl. Pahlawan No. 12, Surabaya',
      birthDate: '2000-11-10',
      gender: 'Perempuan',
      status: UserStatus.aktif,
    ),
    AdminUserModel(
      id: '4',
      name: 'Siti Aisa Nur Apriliana',
      email: 'siti@demo.com',
      phone: '081234567893',
      address: 'Jl. Diponegoro No. 78, Yogyakarta',
      birthDate: '1997-04-18',
      gender: 'Perempuan',
      status: UserStatus.aktif,
    ),
    AdminUserModel(
      id: '5',
      name: 'Nur Alisa Qiroati Sholeha',
      email: 'alisa@demo.com',
      phone: '081234567894',
      address: 'Jl. Ahmad Yani No. 56, Semarang',
      birthDate: '1999-08-05',
      gender: 'Perempuan',
      status: UserStatus.aktif,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminUserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    final q = _searchQuery.toLowerCase();
    return _users.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q);
    }).toList();
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
    if (user.name == 'Nur Alisa Qiroati Sholeha') {
      return 'S'; // Matches mockup Screen 1 & 6
    }
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

            const SizedBox(height: 16),

            // Users List
            Expanded(
              child: _filteredUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data pengguna',
                        style: TextStyle(
                          fontSize: 14,
                          color: subText,
                        ),
                      ),
                    )
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
