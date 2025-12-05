import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../services/supabase_service.dart';
import '../utils/attendance_utils.dart';
import '../widgets/neo_card.dart';

class AttendanceScreen extends StatefulWidget {
  final User user;
  final bool isAdminView;

  const AttendanceScreen({
    super.key,
    required this.user,
    this.isAdminView = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<AttendanceRecord> _allRecords = [];
  List<User> _allEmployees = [];
  User? _selectedEmployee;
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      // Load employee list if admin view
      if (widget.isAdminView) {
        try {
          final employees = await _supabaseService.getAllEmployees();
          if (mounted) {
            setState(() {
              _allEmployees = employees;
              // Default to first employee if available, or reset if list is empty
              if (employees.isNotEmpty) {
                // Only set if null or if current selection is not in the new list
                if (_selectedEmployee == null ||
                    !employees.any((e) => e.id == _selectedEmployee!.id)) {
                  _selectedEmployee = employees.first;
                }
              } else {
                _selectedEmployee = null;
              }
            });
          }
        } catch (e) {
          debugPrint('Error loading employees: $e');
          // Continue even if employee loading fails
          if (mounted) {
            setState(() {
              _allEmployees = [];
              _selectedEmployee = null;
            });
          }
        }
      }

      // Determine which user's records to load
      final targetUserId = widget.isAdminView && _selectedEmployee != null
          ? _selectedEmployee!.id
          : widget.user.id;

      // Load last 6 months of data
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      final records = await _supabaseService.getUserRecordsForDateRange(
        targetUserId,
        sixMonthsAgo,
        now,
      );

      if (mounted) {
        setState(() {
          _allRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // For admin view, show message if no employees
    if (widget.isAdminView && _allEmployees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Employees Found',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add employees to view their attendance',
                style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildHoursSummary(),
            const SizedBox(height: 24),
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildCalendar(),
            const SizedBox(height: 24),
            _buildDailyDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.brand, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTENDANCE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.isAdminView
                          ? 'View employee attendance'
                          : 'Track your work hours',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Employee selector for admin view
          if (widget.isAdminView &&
              _allEmployees.isNotEmpty &&
              _selectedEmployee != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.white : Colors.black,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<User>(
                  value: _selectedEmployee,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  items: _allEmployees.map((employee) {
                    return DropdownMenuItem<User>(
                      value: employee,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.brand,
                            child: Text(
                              employee.name.isNotEmpty ? employee.name[0] : '?',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  employee.name,
                                  style: GoogleFonts.spaceMono(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  employee.department,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (User? newEmployee) {
                    if (newEmployee != null) {
                      setState(() {
                        _selectedEmployee = newEmployee;
                      });
                      _loadAttendanceData();
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHoursSummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayHours = AttendanceUtils.calculateTotalHours(_allRecords, today);
    final weekHours = AttendanceUtils.calculateWeeklyHours(_allRecords);
    final monthHours = AttendanceUtils.calculateMonthlyHours(
      _allRecords,
      now.month,
      now.year,
    );
    final allTimeHours = AttendanceUtils.calculateAllTimeHours(_allRecords);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildHourCard('TODAY', todayHours, Icons.today),
        _buildHourCard('THIS WEEK', weekHours, Icons.calendar_view_week),
        _buildHourCard('THIS MONTH', monthHours, Icons.calendar_month),
        _buildHourCard('ALL TIME', allTimeHours, Icons.all_inclusive),
      ],
    );
  }

  Widget _buildHourCard(String label, double hours, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeoCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              Icon(
                icon,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ],
          ),
          Text(
            AttendanceUtils.formatHours(hours),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = AttendanceUtils.getLastNMonths(6);

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month.year == _currentMonth.year &&
              month.month == _currentMonth.month;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildMonthChip(month, isSelected),
          );
        },
      ),
    );
  }

  Widget _buildMonthChip(DateTime month, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMonth = month;
          _selectedDate = month;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brand
              : (isDark ? AppColors.darkSurface : Colors.white),
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.white : Colors.black,
                    offset: const Offset(4, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM').format(month).toUpperCase(),
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.black : null,
              ),
            ),
            Text(
              DateFormat('yyyy').format(month),
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: isSelected ? Colors.black54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstDay = AttendanceUtils.getFirstDayOfMonth(_currentMonth);
    final lastDay = AttendanceUtils.getLastDayOfMonth(_currentMonth);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // 0 = Sunday

    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth).toUpperCase(),
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                AttendanceUtils.formatHours(AttendanceUtils.calculateMonthlyHours(_allRecords, _currentMonth.month, _currentMonth.year)),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox(); // Empty cells before month starts
              }

              final day = index - firstWeekday + 1;
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, day);
              final hours =
                  AttendanceUtils.calculateTotalHours(_allRecords, date);
              final status = AttendanceUtils.getDayStatus(hours);
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isFuture = date.isAfter(DateTime.now());

              return _buildCalendarDay(
                day,
                date,
                status,
                isToday,
                isSelected,
                isFuture,
                isDark,
              );
            },
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                  'Full Day (8+ hrs)', _getStatusColor('full', false)),
              _buildLegendItem(
                  'Partial (4-8 hrs)', _getStatusColor('partial', false)),
              _buildLegendItem(
                  'Minimal (<4 hrs)', _getStatusColor('minimal', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    int day,
    DateTime date,
    String status,
    bool isToday,
    bool isSelected,
    bool isFuture,
    bool isDark,
  ) {
    final color = isFuture ? Colors.grey[300] : _getStatusColor(status, isDark);

    return GestureDetector(
      onTap: isFuture
          ? null
          : () {
              setState(() {
                _selectedDate = date;
              });
            },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isToday ? AppColors.brand : Colors.transparent),
            width: isSelected ? 3 : (isToday ? 2 : 0),
          ),
        ),
        child: Center(
          child: Text(
            '$day',
            style: GoogleFonts.spaceMono(
              fontWeight:
                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              color: status == 'full' || status == 'partial'
                  ? Colors.black
                  : (isFuture
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black)),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'full':
        return AppColors.brand;
      case 'partial':
        return Colors.amber;
      case 'minimal':
        return Colors.red[300]!;
      case 'none':
      default:
        return isDark ? AppColors.darkSurface : Colors.grey[100]!;
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.spaceMono(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDailyDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayRecords =
        AttendanceUtils.getAttendanceForDate(_allRecords, _selectedDate);
    final totalHours =
        AttendanceUtils.calculateTotalHours(_allRecords, _selectedDate);

    return NeoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, yyyy')
                          .format(_selectedDate)
                          .toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${AttendanceUtils.formatHours(totalHours, detailed: true)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2),
          if (dayRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '> No attendance records for this day.',
                style: GoogleFonts.spaceMono(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayRecords.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = dayRecords[index];
                return _buildRecordTile(record, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(AttendanceRecord record, bool isDark) {
    IconData icon;
    Color iconColor;
    String label;

    switch (record.type) {
      case AttendanceType.CLOCK_IN:
        icon = Icons.play_arrow;
        iconColor = AppColors.brand;
        label = 'CLOCK IN';
        break;
      case AttendanceType.CLOCK_OUT:
        icon = Icons.stop;
        iconColor = Colors.red;
        label = 'CLOCK OUT';
        break;
      case AttendanceType.BREAK_START:
        icon = Icons.coffee;
        iconColor = Colors.amber;
        label = 'BREAK START';
        break;
      case AttendanceType.BREAK_END:
        icon = Icons.restaurant;
        iconColor = Colors.blue;
        label = 'BREAK END';
        break;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          border: Border.all(color: iconColor, width: 2),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('hh:mm a').format(
              DateTime.fromMillisecondsSinceEpoch(record.timestamp),
            ),
            style: GoogleFonts.spaceMono(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (record.location != null)
            const Icon(
              Icons.location_on,
              size: 12,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }
}
