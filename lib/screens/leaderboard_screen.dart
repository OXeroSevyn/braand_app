import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';

import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../constants.dart';
import '../widgets/user_avatar.dart';
import 'admin_task_review_screen.dart';

import '../services/gamification_service.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final GamificationService _gamificationService = GamificationService();
  final StreamController<List<LeaderboardEntry>> _leaderboardController =
      StreamController<List<LeaderboardEntry>>();
  Timer? _refreshTimer;
  List<User> _employees = [];
  bool _isLoading = true;
  String _selectedFilter = 'Month'; // 'Today', 'Month', 'Year', 'All Time'

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _leaderboardController.close();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _supabaseService.getAllEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
        _startRealtimeUpdates();
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startRealtimeUpdates() {
    _refreshLeaderboard(); // Initial fetch
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLeaderboard();
    });
  }

  Future<void> _refreshLeaderboard() async {
    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (_selectedFilter) {
        case 'Today':
          start = DateTime(now.year, now.month, now.day);
          break;
        case 'Month':
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Year':
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case 'All Time':
          start = DateTime(2020); // Arbitrary past date
          break;
        default:
          start = DateTime(now.year, now.month, 1);
      }

      final tasks = await _supabaseService.getTasksForDateRange(
        start,
        end,
      );

      final leaderboard =
          _gamificationService.calculateLeaderboard(tasks, _employees);
      if (!_leaderboardController.isClosed) {
        _leaderboardController.add(leaderboard);
      }
    } catch (e) {
      debugPrint('Error refreshing leaderboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = Provider.of<AuthProvider>(context).user;
    final isAdmin = currentUser?.role == 'Admin';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'LEADERBOARD',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFilterChip('Today', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Month', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Year', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<List<LeaderboardEntry>>(
                    stream: _leaderboardController.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final entries = snapshot.data!;
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            'No Data Available',
                            style: GoogleFonts.spaceMono(color: Colors.grey),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Top 3 Podium
                          _buildPodium(entries, isDark),

                          // Reduced gap here
                          const SizedBox(height: 10),

                          // List
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                    top: 20, left: 20, right: 20, bottom: 20),
                                itemCount:
                                    entries.length > 3 ? entries.length - 3 : 0,
                                itemBuilder: (context, index) {
                                  final entry = entries[index + 3];
                                  return _buildListTile(entry, isDark, isAdmin);
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _refreshLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand
              : (isDark ? Colors.white10 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.black
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries, bool isDark) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 250, // Reduced podium height slightly
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 2nd Place
          if (entries.length > 1)
            Positioned(
              left: 30, // Adjusted layout
              bottom: 0,
              child: _buildPodiumStep(
                entries[1],
                isDark,
                height: 160,
                color: Colors.grey.shade400,
                rank: 2,
              ),
            ),

          // 3rd Place
          if (entries.length > 2)
            Positioned(
              right: 30, // Adjusted layout
              bottom: 0,
              child: _buildPodiumStep(
                entries[2],
                isDark,
                height: 140,
                color: const Color(0xFFCD7F32), // Bronze
                rank: 3,
              ),
            ),

          // 1st Place
          Positioned(
            left: 0,
            right: 0,
            bottom: 20, // Lifted up slightly
            child: _buildPodiumStep(
              entries[0],
              isDark,
              height: 200,
              color: const Color(0xFFFFD700), // Gold
              rank: 1,
              isFirst: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(
    LeaderboardEntry entry,
    bool isDark, {
    required double height,
    required Color color,
    required int rank,
    bool isFirst = false,
  }) {
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).user?.role == 'Admin';

    return GestureDetector(
      onTap: isAdmin
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdminTaskReviewScreen(employee: entry.user),
                ),
              )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for 1st
          if (isFirst)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(Icons.emoji_events, color: color, size: 28),
            ),

          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: UserAvatar(
                  avatarUrl: entry.user.avatar,
                  name: entry.user.name,
                  size: isFirst ? 70 : 50,
                ),
              ),
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    rank.toString(),
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            entry.user.name.split(' ')[0], // First name only
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            '${entry.score} pts',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isFirst) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildListTile(LeaderboardEntry entry, bool isDark, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        onTap: isAdmin
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminTaskReviewScreen(employee: entry.user),
                  ),
                )
            : null,
        leading: Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            '#${entry.rank}',
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        title: Row(
          children: [
            UserAvatar(
              avatarUrl: entry.user.avatar,
              name: entry.user.name,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${entry.tasksCompleted} tasks completed',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brand),
          ),
          child: Text(
            '${entry.score}',
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}
