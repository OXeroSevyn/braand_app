import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';

class AdminEmployeeListScreen extends StatefulWidget {
  const AdminEmployeeListScreen({super.key});

  @override
  State<AdminEmployeeListScreen> createState() =>
      _AdminEmployeeListScreenState();
}

class _AdminEmployeeListScreenState extends State<AdminEmployeeListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<User> _employees = [];
  List<User> _filteredEmployees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _supabaseService.getAllEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _filteredEmployees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((user) {
          final name = user.name.toLowerCase();
          final dept = user.department.toLowerCase();
          final email = user.email.toLowerCase();
          return name.contains(query) ||
              dept.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EMPLOYEES',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, department...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.black : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredEmployees.isEmpty
              ? Center(
                  child: Text(
                    _employees.isEmpty ? 'NO EMPLOYEES FOUND' : 'NO MATCHES',
                    style: GoogleFonts.spaceMono(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = _filteredEmployees[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                user: employee,
                                isOwnProfile: false,
                              ),
                            ),
                          );
                        },
                        child: NeoCard(
                          child: Row(
                            children: [
                              UserAvatar(
                                avatarUrl: employee.avatar,
                                name: employee.name,
                                size: 50,
                                showBorder: true,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employee.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            employee.department.toUpperCase(),
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        if (employee.role == 'Admin') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.brand,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'ADMIN',
                                              style: GoogleFonts.spaceMono(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      employee.email,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
