import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';
import '../widgets/user_avatar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late TabController _tabController;
  List<User> _pendingUsers = [];
  List<User> _activeUsers = [];
  List<User> _rejectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔍 UserManagement: Fetching users...');

      final pending = await _supabaseService.getPendingUsers();
      debugPrint('📋 Pending users: ${pending.length}');
      for (var user in pending) {
        debugPrint('  - ${user.name} (${user.email}) - ${user.status}');
      }

      final active = await _supabaseService.getAllEmployees();
      debugPrint('✅ Active users: ${active.length}');
      for (var user in active) {
        debugPrint('  - ${user.name} (${user.email}) - ${user.status}');
      }

      // Fetch rejected users
      final rejected = await _supabaseService.getRejectedUsers();
      debugPrint('❌ Rejected users: ${rejected.length}');
      for (var user in rejected) {
        debugPrint('  - ${user.name} (${user.email}) - ${user.status}');
      }

      setState(() {
        _pendingUsers = pending;
        _activeUsers = active;
        _rejectedUsers = rejected;
        _isLoading = false;
      });

      debugPrint('✅ User management loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading users: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(User user, String status) async {
    try {
      await _supabaseService.updateUserStatus(user.id, status);
      await _loadUsers(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${user.name} marked as $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'USER MANAGEMENT',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
          indicatorColor: AppColors.brand,
          labelColor: isDark ? Colors.white : Colors.black,
          tabs: const [
            Tab(text: 'PENDING'),
            Tab(text: 'ACTIVE'),
            Tab(text: 'REJECTED'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_pendingUsers, isPending: true),
                _buildUserList(_activeUsers),
                _buildUserList(_rejectedUsers, isRejected: true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement Invite Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite feature coming soon')),
          );
        },
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: Text(
          'INVITE USER',
          style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildUserList(List<User> users,
      {bool isPending = false, bool isRejected = false}) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          'NO USERS FOUND',
          style: GoogleFonts.spaceMono(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeoCard(
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: user.avatar,
                  name: user.name,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${user.role} // ${user.department}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPending) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _updateStatus(user, 'active'),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _updateStatus(user, 'rejected'),
                    tooltip: 'Reject',
                  ),
                ] else if (!isRejected) ...[
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.red),
                    onPressed: () => _updateStatus(user, 'rejected'),
                    tooltip: 'Deactivate',
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () => _updateStatus(user, 'active'),
                    tooltip: 'Reactivate',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
