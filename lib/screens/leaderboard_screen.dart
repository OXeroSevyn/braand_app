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
import '../widgets/glass_container.dart';
import '../widgets/neo_card.dart';

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

                          const SizedBox(height: 10),

                          // List
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount:
                                  entries.length > 3 ? entries.length - 3 : 0,
                              itemBuilder: (context, index) {
                                final entry = entries[index + 3];
                                return _buildGamifiedCard(
                                    entry, isDark, isAdmin);
                              },
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (entries.length > 1)
            _buildPodiumStep(
              entries[1],
              isDark,
              height: 120,
              color: Colors.grey.shade400,
              rank: 2,
            ),
          const SizedBox(width: 8),

          // 1st Place
          _buildPodiumStep(
            entries[0],
            isDark,
            height: 150,
            color: const Color(0xFFFFD700), // Gold
            rank: 1,
            isFirst: true,
          ),
          const SizedBox(width: 8),

          // 3rd Place
          if (entries.length > 2)
            _buildPodiumStep(
              entries[2],
              isDark,
              height: 100,
              color: const Color(0xFFCD7F32), // Bronze
              rank: 3,
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isAdmin
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdminTaskReviewScreen(employee: entry.user),
                    ),
                  )
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              UserAvatar(
                avatarUrl: entry.user.avatar,
                name: entry.user.name,
                size: isFirst ? 80 : 65,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          width: isFirst ? 100 : 80,
          height: height,
          opacity: 0.1,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.user.name.split(' ')[0],
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.score}',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamifiedCard(LeaderboardEntry entry, bool isDark, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeoCard(
        padding: const EdgeInsets.all(12),
        onTap: isAdmin
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminTaskReviewScreen(employee: entry.user),
                  ),
                )
            : null,
        child: Row(
          children: [
            Container(
              width: 30,
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            UserAvatar(
              avatarUrl: entry.user.avatar,
              name: entry.user.name,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      _buildMiniTag('✅ ${entry.tasksCompleted}'),
                      const SizedBox(width: 4),
                      _buildMiniTag('🎭 ${entry.moodPoints}'),
                      const SizedBox(width: 4),
                      _buildMiniTag('📅 ${entry.attendancePoints}'),
                      const SizedBox(width: 4),
                      _buildMiniTag(_getTrendIcon(entry.trend)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.score}',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.brand,
                  ),
                ),
                Text(
                  'POINTS',
                  style: GoogleFonts.spaceMono(fontSize: 8, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(fontSize: 8, color: Colors.grey),
      ),
    );
  }

  String _getTrendIcon(String trend) {
    switch (trend) {
      case 'UP':
        return '📈';
      case 'DOWN':
        return '📉';
      default:
        return '➖';
    }
  }
}
