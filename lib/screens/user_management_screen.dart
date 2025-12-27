import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';
import '../widgets/user_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

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
        onPressed: _showInviteDialog,
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

  Future<void> _showInviteDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String branch = 'Sales';
    String role = 'Employee'; // Default role

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'INVITE NEW USER',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'john@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: ['Employee', 'Admin']
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => role = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: branch,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: ['Sales', 'Marketing', 'Development', 'HR', 'Design']
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => branch = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL',
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      emailController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _sendInviteEmail(
                      name: nameController.text,
                      email: emailController.text,
                      role: role,
                      department: branch,
                    );
                  }
                },
                child: Text('SEND INVITE',
                    style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendInviteEmail({
    required String name,
    required String email,
    required String role,
    required String department,
  }) async {
    final String subject = 'Invitation to join Braand App as $role';
    final String body =
        'Hello $name,\n\nYou have been invited to join the Braand App team as a $role in the $department department.\n\nPlease download the app and sign up with this email: $email\n\nBest regards,\nBraand Team';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      // Try to launch directly with external application mode
      // We skip canLaunchUrl because it can be flaky on some Android versions even with queries
      if (!await launchUrl(emailLaunchUri,
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch email client';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (mounted) {
        await Clipboard.setData(
            ClipboardData(text: 'Subject: $subject\n\n$body'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Could not open email. Invite copied to clipboard!'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );

        // You might need to import 'package:flutter/services.dart'; for Clipboard
        // But since this is a quick fix, I'll ensure imports are correct in a separate step or just use the tool.
        // Actually, let's use the Clipboard class correctly.
      }
    }
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
