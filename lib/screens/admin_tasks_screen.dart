import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/task.dart';
import '../models/task_report_data.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ReportService _reportService = ReportService();

  DateTime _startDate =
      DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  List<User> _employees = [];
  List<Task> _tasks = [];
  User? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final emps = await _supabaseService.getAllEmployees();
      final tasks =
          await _supabaseService.getTasksForDateRange(_startDate, _endDate);

      if (mounted) {
        setState(() {
          _employees = emps;
          _tasks = tasks;
        });
      }
    } catch (e) {
      debugPrint('Error loading task data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      await _loadData();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      await _loadData();
    }
  }

  List<Task> get _filteredTasks {
    if (_selectedEmployee == null) return _tasks;
    return _tasks.where((t) => t.userId == _selectedEmployee!.id).toList();
  }

  List<TaskReportData> _buildTaskReportData() {
    final Map<String, List<Task>> byUser = {};

    for (final task in _filteredTasks) {
      byUser.putIfAbsent(task.userId, () => []).add(task);
    }

    final List<TaskReportData> result = [];
    for (final entry in byUser.entries) {
      final user =
          _employees.firstWhere((u) => u.id == entry.key, orElse: () => User(
                id: entry.key,
                email: '',
                name: 'Unknown',
                role: 'Employee',
                department: '',
              ));
      result.add(TaskReportData(user: user, tasks: entry.value));
    }
    return result;
  }

  Future<void> _exportExcel() async {
    final data = _buildTaskReportData();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to export')),
      );
      return;
    }
    await _reportService.generateAndShareTaskExcel(
        data, _startDate, _endDate);
  }

  Future<void> _exportPdf() async {
    final data = _buildTaskReportData();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to export')),
      );
      return;
    }
    await _reportService.generateAndShareTaskPdf(
        data, _startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.brand, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TASK REPORTS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'View employee tasks and export to Excel / PDF',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filters
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_alt, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'FILTERS',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateChip(
                          label: 'START',
                          date: _startDate,
                          onTap: _pickStartDate,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateChip(
                          label: 'END',
                          date: _endDate,
                          onTap: _pickEndDate,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_employees.isNotEmpty)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<User?>(
                        value: _selectedEmployee,
                        isExpanded: true,
                        hint: Text(
                          'All employees',
                          style: GoogleFonts.spaceMono(fontSize: 12),
                        ),
                        items: [
                          const DropdownMenuItem<User?>(
                            value: null,
                            child: Text('All employees'),
                          ),
                          ..._employees.map((emp) {
                            return DropdownMenuItem<User?>(
                              value: emp,
                              child: Text(
                                emp.name,
                                style: GoogleFonts.spaceMono(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedEmployee = value;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Export buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: Text(
                      'EXPORT EXCEL',
                      style: GoogleFonts.spaceMono(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(
                      'EXPORT PDF',
                      style: GoogleFonts.spaceMono(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary card with total hours
            if (_filteredTasks.isNotEmpty)
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SUMMARY',
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Total Tasks',
                            '${_filteredTasks.length}',
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryItem(
                            'Completed',
                            '${_filteredTasks.where((t) => t.isCompleted).length}',
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryItem(
                            'Total Hours',
                            _buildTaskReportData()
                                .fold<double>(
                                  0.0,
                                  (sum, report) => sum + report.totalHours,
                                )
                                .toStringAsFixed(1),
                            isDark,
                            isHighlight: true,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedEmployee == null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Hours by Employee',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildTaskReportData().map((report) {
                        if (report.totalHours == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                report.user.name,
                                style: GoogleFonts.spaceMono(fontSize: 11),
                              ),
                              Text(
                                '${report.totalHours.toStringAsFixed(1)}h',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Task table
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TASKS',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_filteredTasks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'NO TASKS IN THIS RANGE',
                          style: GoogleFonts.spaceMono(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _filteredTasks.map((task) {
                        final user = _employees.firstWhere(
                          (e) => e.id == task.userId,
                          orElse: () => User(
                            id: task.userId,
                            email: '',
                            name: 'Unknown',
                            role: 'Employee',
                            department: '',
                          ),
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black
                                : (task.isCompleted
                                    ? Colors.green[50]
                                    : Colors.grey[100]),
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.department,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (task.description != null &&
                                        task.description!.isNotEmpty)
                                      Text(
                                        task.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('yyyy-MM-dd')
                                          .format(task.date),
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (task.startTime != null ||
                                        task.endTime != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        task.startTime != null && task.endTime != null
                                            ? '${task.startTime!.format(context)} - ${task.endTime!.format(context)}'
                                            : task.startTime != null
                                                ? 'From ${task.startTime!.format(context)}'
                                                : 'Until ${task.endTime!.format(context)}',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 9,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (task.durationInHours != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${task.durationInHours!.toStringAsFixed(1)}h',
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                      ],
                                    ],
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: task.isCompleted
                                            ? Colors.green
                                            : Colors.orange,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        task.isCompleted
                                            ? 'DONE'
                                            : 'PENDING',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border.all(
          color: isHighlight ? AppColors.brand : (isDark ? Colors.white : Colors.black),
          width: isHighlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.brand : null,
            ),
          ),
        ],
      ),
    );
  }
}


